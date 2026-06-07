import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import '../services/pdf_service.dart';
import '../services/song_storage_service.dart';
import '../services/search_service.dart';
import '../utils/load_songs_from_json.dart';
import '../utils/json_parser_helper.dart';

class SongProvider extends ChangeNotifier {
  final PDFService _pdfService = PDFService();
  final SongStorageService _storageService = SongStorageService();
  final SearchService _searchService = SearchService();
  StreamSubscription? _firestoreSubscription;
  StreamSubscription<User?>? _authSubscription;

  // ── Hidden category ────────────────────────────────────────────────────
  // Songs from the Gilgal 2025-2026 PDF booklet (≈40 songs) are stored in
  // Firestore/Hive under this category. They are not shown in the UI for now.
  static const String _hiddenCategory = 'Gilgal Worship 2025-2026';

  static bool _isVisible(Song song) => song.category != _hiddenCategory;

  List<Song> _allSongs = [];
  List<Song> _selectedSongs = [];
  Set<String> _selectedSongIds = <String>{};
  List<Song> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _searchDebounce;
  Timer? _searchIndexDebounce;
  Timer? _selectedSaveDebounce;
  Timer? _libraryPersistDebounce;
  Timer? _firestoreDebounce;
  bool _isSearchIndexBuilding = false;
  bool _pendingIndexRebuild = false;
  bool _pendingRefreshActiveSearch = false;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 280);
  static const Duration _searchIndexDebounceDuration =
      Duration(milliseconds: 700);
  static const Duration _selectedSaveDebounceDuration =
      Duration(milliseconds: 180);
  static const Duration _libraryPersistDebounceDuration =
      Duration(milliseconds: 500);
  static const Duration _firestoreDebounceDuration =
      Duration(milliseconds: 500);
  bool _disposed = false;

  List<Song> get allSongs => _allSongs;
  List<Song> get selectedSongs => _selectedSongs;
  List<Song> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool isSelected(String songId) => _selectedSongIds.contains(songId);

  SongProvider() {
    _isLoading = true;
    _loadSelectedSongs();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        ensureFirestoreSync();
      } else {
        _firestoreSubscription?.cancel();
        _firestoreSubscription = null;
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadSongs());
  }

  /// Starts Firestore sync once the user is authenticated.
  void ensureFirestoreSync() {
    if (FirebaseAuth.instance.currentUser == null) return;
    if (_firestoreSubscription != null) return;
    _attachFirestoreListener();
  }

  // =========================
  // LOAD SONGS FROM HIVE / JSON
  // =========================
  Future<void> _loadSongs() async {
    // Yield so loading screen paints before any heavy work (prevents ANR)
    await Future.delayed(Duration.zero);

    final box = Hive.box<Song>('songs');
    List<Song> loadedSongs = await _readSongsFromHiveInBatches(box);

    // Strip hidden-category songs from the cache.
    loadedSongs = loadedSongs.where(_isVisible).toList();

    // If the cache has very few songs it means a PDF import replaced the real
    // library. Clear everything so we fall back to the bundled songs.json.
    if (loadedSongs.isNotEmpty && loadedSongs.length < 100) {
      await box.clear();
      await _storageService.deleteLocalSongsFile();
      loadedSongs = [];
    }

    // Fast path: we have a healthy cached library
    if (loadedSongs.isNotEmpty) {
      await Future.delayed(Duration.zero);
      loadedSongs.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
      _allSongs = loadedSongs;
      if (_searchQuery.trim().isEmpty) {
        _searchResults = _allSongs;
      }
      _isLoading = false;
      notifyListeners(); // show songs immediately; index built after
      _attachFirestoreListener();
      return;
    }

    // Slow path: load from file or assets

    // Prefer local JSON file if it exists (user-imported songs)
    if (loadedSongs.isEmpty) {
      final localSongs =
          (await _storageService.loadLocalSongs()).where(_isVisible).toList();
      // Only trust the local file if it contains a real library (not a tiny PDF import)
      if (localSongs.length >= 100) {
        await box.clear();
        await box.putAll({for (final song in localSongs) song.id: song});
        loadedSongs = localSongs;
      } else if (localSongs.isNotEmpty) {
        // Stale PDF import file — delete it so the bundled JSON is used
        await _storageService.deleteLocalSongsFile();
      }
    }

    // fallback to bundled JSON if hive empty (skip bad PDF entries)
    if (loadedSongs.isEmpty) {
      final jsonString = await rootBundle.loadString('assets/songs.json');
      loadedSongs = await JsonParserHelper.parseSongsFromJson(jsonString);
      // Use putAll for a single bulk write instead of 700 individual awaited puts.
      await box.putAll({for (final song in loadedSongs) song.id: song});
      await _storageService.saveLocalSongs(loadedSongs);
    }

    await Future.delayed(Duration.zero);
    loadedSongs.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    _allSongs = loadedSongs;
    if (_searchQuery.trim().isEmpty) {
      _searchResults = _allSongs;
    }
    _isLoading = false;
    notifyListeners(); // show songs immediately; index built after
    _attachFirestoreListener();
  }

  Future<List<Song>> _readSongsFromHiveInBatches(Box<Song> box) async {
    if (box.isEmpty) return const <Song>[];
    final keys = box.keys.toList(growable: false);
    final loaded = <Song>[];
    const batchSize = 20;
    for (int i = 0; i < keys.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, keys.length);
      for (int j = i; j < end; j++) {
        final song = box.get(keys[j]);
        if (song != null) loaded.add(song);
      }
      await Future.delayed(Duration.zero);
    }
    return loaded;
  }

  void _attachFirestoreListener() {
    // Firestore rules require auth; skip for guest/unauthenticated sessions.
    if (FirebaseAuth.instance.currentUser == null) return;

    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('songs')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty || snapshot.docChanges.isEmpty) return;
      final changes =
          List<DocumentChange<Map<String, dynamic>>>.from(snapshot.docChanges);
      _firestoreDebounce?.cancel();
      _firestoreDebounce = Timer(_firestoreDebounceDuration, () {
        _processFirestoreDocChanges(changes);
      });
    });
  }

  /// Applies only changed Firestore documents to local state.
  /// This avoids reparsing all 700 songs on every snapshot and prevents ANR.
  Future<void> _processFirestoreDocChanges(
    List<DocumentChange<Map<String, dynamic>>> changes,
  ) async {
    try {
      if (changes.isEmpty) return;
      const batchSize = 4;
      final songsById = {for (final song in _allSongs) song.id: song};
      bool songsChanged = false;

      for (int i = 0; i < changes.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, changes.length);
        for (int j = i; j < end; j++) {
          try {
            final change = changes[j];
            final raw = change.doc.data();
            final fallbackId = change.doc.id;
            final rawId = raw?['id'];
            final docId =
                rawId is String && rawId.isNotEmpty ? rawId : fallbackId;

            if (change.type == DocumentChangeType.removed) {
              if (songsById.remove(docId) != null) {
                songsChanged = true;
              }
              continue;
            }

            if (raw == null) continue;
            final data = _normalizeFirestoreMap(raw);
            final dataId = data['id'];
            if (dataId is! String || dataId.isEmpty) {
              data['id'] = docId;
            }
            final song = Song.fromJson(data);

            if (!_isVisible(song)) {
              if (songsById.remove(song.id) != null) {
                songsChanged = true;
              }
              continue;
            }

            final existing = songsById[song.id];
            if (existing == null || !_isSameSong(existing, song)) {
              songsById[song.id] = song;
              songsChanged = true;
            }
          } catch (e) {
            debugPrint('[SongProvider] Skipping bad Firestore doc: $e');
          }
        }
        // Yield every batch so no single burst blocks the UI thread.
        await Future.delayed(const Duration(milliseconds: 1));
      }

      if (!songsChanged) return;

      final merged = songsById.values.toList()
        ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
      _allSongs = merged;
      final selectedChanged = _syncSelectedSongsWithAllSongs(songsById);
      if (_searchQuery.trim().isEmpty) {
        _searchResults = _allSongs;
      }

      if (selectedChanged) {
        _scheduleSaveSelected();
      }

      notifyListeners();

      // Rebuild index only when user is actively searching.
      if (_searchQuery.trim().isNotEmpty) {
        _scheduleSearchIndexRebuild(refreshActiveSearch: true);
      }
    } catch (e) {
      debugPrint('[SongProvider] Firestore snapshot processing error: $e');
    }
  }

  static bool _isSameSong(Song a, Song b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.pageNumber == b.pageNumber &&
        a.category == b.category &&
        a.lyrics == b.lyrics &&
        a.lyricsEnglish == b.lyricsEnglish &&
        a.chords == b.chords;
  }

  bool _syncSelectedSongsWithAllSongs(Map<String, Song> songsById) {
    if (_selectedSongs.isEmpty) return false;
    bool changed = false;
    final updated = <Song>[];
    for (final selectedSong in _selectedSongs) {
      final latest = songsById[selectedSong.id];
      if (latest == null) {
        changed = true;
        continue;
      }
      if (!_isSameSong(selectedSong, latest)) {
        changed = true;
      }
      updated.add(latest);
    }
    if (!changed) return false;
    _selectedSongs = updated;
    _selectedSongIds = updated.map((song) => song.id).toSet();
    return true;
  }

  void _scheduleSearchIndexRebuild({required bool refreshActiveSearch}) {
    _pendingRefreshActiveSearch =
        _pendingRefreshActiveSearch || refreshActiveSearch;
    _searchIndexDebounce?.cancel();
    _searchIndexDebounce = Timer(_searchIndexDebounceDuration, () {
      _runSearchIndexRebuild(refreshActiveSearch: _pendingRefreshActiveSearch);
      _pendingRefreshActiveSearch = false;
    });
  }

  void _runSearchIndexRebuild({required bool refreshActiveSearch}) {
    if (_disposed) return;

    if (_isSearchIndexBuilding) {
      _pendingIndexRebuild = true;
      _pendingRefreshActiveSearch =
          _pendingRefreshActiveSearch || refreshActiveSearch;
      return;
    }

    _isSearchIndexBuilding = true;
    final songsSnapshot = List<Song>.from(_allSongs);
    unawaited(
      _searchService.buildIndexAsync(songsSnapshot).then((_) {
        if (_disposed) return;
        if (!refreshActiveSearch) return;
        if (_searchQuery.trim().isEmpty) return;
        _searchResults = _searchService.search(_searchQuery, maxResults: 50);
        notifyListeners();
      }).catchError((e) {
        debugPrint('[SongProvider] Search index rebuild error: $e');
      }).whenComplete(() {
        if (_disposed) return;
        _isSearchIndexBuilding = false;
        if (_pendingIndexRebuild) {
          final shouldRefresh = _pendingRefreshActiveSearch;
          _pendingIndexRebuild = false;
          _pendingRefreshActiveSearch = false;
          _runSearchIndexRebuild(refreshActiveSearch: shouldRefresh);
        }
      }),
    );
  }

  List<Song> _fallbackSearch(String query, {int maxResults = 50}) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return _allSongs;
    final out = <Song>[];
    for (final song in _allSongs) {
      if (song.displayTitle.toLowerCase().contains(needle) ||
          (song.lyrics ?? '').toLowerCase().contains(needle) ||
          (song.lyricsEnglish ?? '').toLowerCase().contains(needle)) {
        out.add(song);
        if (out.length >= maxResults) break;
      }
    }
    return out;
  }

  /// Converts Firestore map so Song.fromJson works (e.g. Timestamp → ISO string).
  static Map<String, dynamic> _normalizeFirestoreMap(
      Map<String, dynamic> data) {
    final out = Map<String, dynamic>.from(data);
    if (out['createdAt'] != null && out['createdAt'] is Timestamp) {
      out['createdAt'] =
          (out['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    return out;
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    _searchIndexDebounce?.cancel();
    _selectedSaveDebounce?.cancel();
    _libraryPersistDebounce?.cancel();
    _firestoreDebounce?.cancel();
    _firestoreSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // ✅ REQUIRED (was missing)
  Future<void> refreshSongs() async {
    await _loadSongs();
  }

  // ✅ FIX: CLEAR OLD PDF DATA & LOAD FULL JSON SONGS
  Future<void> resetAndLoadFromJson() async {
    final box = Hive.box<Song>('songs');
    await box.clear(); // 🔥 remove truncated songs
    await loadSongsFromJson(); // 🔥 load full songs.json
    await refreshSongs(); // 🔥 refresh UI
  }

  Future<bool> reloadFromLocalStorage() async {
    final localSongs = await _storageService.loadLocalSongs();
    if (localSongs.isEmpty) {
      return false;
    }
    final box = Hive.box<Song>('songs');
    await box.clear();
    await box.putAll({for (final song in localSongs) song.id: song});
    await refreshSongs();
    return true;
  }

  // =========================
  // SELECTED SONGS
  // =========================
  Future<void> _loadSelectedSongs() async {
    final box = Hive.box<List>('selectedSongs');
    final ids = box.get('ids', defaultValue: <String>[]) as List;
    final songBox = Hive.box<Song>('songs');

    _selectedSongs =
        ids.map((id) => songBox.get(id)).whereType<Song>().toList();
    _selectedSongIds = _selectedSongs.map((s) => s.id).toSet();

    notifyListeners();
  }

  /// Adds the song to the playlist. Uses the song from [allSongs] by id so only
  /// that one song (the one you tapped) is added, with latest data.
  Future<void> addToSelected(Song song) async {
    if (_selectedSongIds.contains(song.id)) return;
    final idx = _allSongs.indexWhere((s) => s.id == song.id);
    final toAdd = idx >= 0 ? _allSongs[idx] : song;
    _selectedSongs.add(toAdd);
    _selectedSongIds.add(toAdd.id);
    _scheduleSaveSelected();
    notifyListeners();
  }

  Future<void> removeFromSelected(Song song) async {
    if (!_selectedSongIds.contains(song.id)) return;
    _selectedSongs.removeWhere((s) => s.id == song.id);
    _selectedSongIds.remove(song.id);
    _scheduleSaveSelected();
    notifyListeners();
  }

  Future<void> clearSelected() async {
    if (_selectedSongs.isEmpty) return;
    _selectedSongs.clear();
    _selectedSongIds.clear();
    _scheduleSaveSelected();
    notifyListeners();
  }

  void _scheduleSaveSelected() {
    _selectedSaveDebounce?.cancel();
    _selectedSaveDebounce = Timer(_selectedSaveDebounceDuration, () {
      _selectedSaveDebounce = null;
      unawaited(_saveSelected());
    });
  }

  Future<void> _saveSelected() async {
    final box = Hive.box<List>('selectedSongs');
    await box.put('ids', _selectedSongs.map((e) => e.id).toList());
  }

  void _persistSongInHive(Song song) {
    unawaited(() async {
      try {
        final box = Hive.box<Song>('songs');
        await box.put(song.id, song);
      } catch (e) {
        debugPrint('[SongProvider] Local Hive save error: $e');
      }
    }());
  }

  void _schedulePersistLibrarySnapshot() {
    _libraryPersistDebounce?.cancel();
    _libraryPersistDebounce = Timer(_libraryPersistDebounceDuration, () {
      if (_disposed) return;
      final snapshot = List<Song>.from(_allSongs);
      unawaited(
        _storageService.saveLocalSongs(snapshot).catchError((e) {
          debugPrint('[SongProvider] Local file save error: $e');
        }),
      );
    });
  }

  // =========================
  // UPDATE SONG
  // =========================
  Future<void> updateSong(Song updatedSong) async {
    // Yield so edit screen can pop immediately (avoids "App isn't responding" after save)
    await Future.delayed(Duration.zero);

    _applyLocalSongUpdate(updatedSong);
    notifyListeners();
    _persistSongInHive(updatedSong);
    _schedulePersistLibrarySnapshot();
    if (_searchQuery.trim().isNotEmpty) {
      _scheduleSearchIndexRebuild(refreshActiveSearch: true);
    }

    try {
      await FirebaseFirestore.instance
          .collection('songs')
          .doc(updatedSong.id)
          .set(updatedSong.toJson());
    } catch (e) {
      debugPrint('[SongProvider] Firestore sync error: $e');
      rethrow;
    }
  }

  /// Applies a song update/insert to all local lists and the search index.
  /// Synchronous — no network call.
  void _applyLocalSongUpdate(Song updatedSong) {
    final index = _allSongs.indexWhere((s) => s.id == updatedSong.id);
    if (index != -1) {
      _allSongs[index] = updatedSong;
    } else {
      _allSongs.add(updatedSong);
      _allSongs.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    }

    if (!identical(_searchResults, _allSongs)) {
      final searchIndex =
          _searchResults.indexWhere((s) => s.id == updatedSong.id);
      if (searchIndex != -1) {
        _searchResults[searchIndex] = updatedSong;
      } else {
        _searchResults.add(updatedSong);
        _searchResults.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
      }
    }

    final selectedIndex =
        _selectedSongs.indexWhere((s) => s.id == updatedSong.id);
    if (selectedIndex != -1) {
      _selectedSongs[selectedIndex] = updatedSong;
    }
  }

  // =========================
  // SEARCH - DEBOUNCED & FAST
  // =========================
  void searchSongs(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();

    // Clear: resolve immediately — no copy, no debounce needed
    if (query.trim().isEmpty) {
      _searchDebounce = null;
      _searchResults = _allSongs;
      notifyListeners();
      return;
    }

    // Typing: debounce so we don't search on every keystroke
    _searchDebounce = Timer(_searchDebounceDuration, () {
      _searchDebounce = null;
      _runSearch(query);
    });
  }

  void _runSearch(String query) {
    if (_searchService.isIndexed) {
      _searchResults = _searchService.search(query, maxResults: 50);
    } else {
      _searchResults = _fallbackSearch(query, maxResults: 50);
      _scheduleSearchIndexRebuild(refreshActiveSearch: true);
    }
    notifyListeners();
  }

  // =========================
  // PDF / IMAGE IMPORT
  // =========================
  Future<bool> uploadImages() async {
    _isLoading = true;
    notifyListeners();

    final songs = await _pdfService.parseImagesToSongs();
    if (songs.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await saveImportedSongs(songs);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> uploadPdf() async {
    _isLoading = true;
    notifyListeners();

    final songs = await _pdfService.parsePDFToSongs();
    if (songs.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await saveImportedSongs(songs);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // =========================
  // IMPORT (PREVIEW + SAVE)
  // =========================
  Future<List<Song>> parsePdfForPreview() async {
    return _pdfService.parsePDFToSongs();
  }

  Future<List<Song>> parseImagesForPreview() async {
    return _pdfService.parseImagesToSongs();
  }

  Future<void> saveImportedSongs(List<Song> songs) async {
    final normalized = _normalizeImportedSongs(songs);
    if (normalized.isEmpty) return;

    // Merge into the existing library — never wipe the full bundled catalog.
    final mergedById = {for (final song in _allSongs) song.id: song};
    for (final song in normalized) {
      mergedById[song.id] = song;
    }
    final merged = mergedById.values.toList()
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));

    final box = Hive.box<Song>('songs');
    await box.clear();
    await box.putAll({for (final song in merged) song.id: song});
    await _storageService.saveLocalSongs(merged);

    _allSongs = merged;
    if (_searchQuery.trim().isEmpty) {
      _searchResults = _allSongs;
    }
    _scheduleSearchIndexRebuild(
      refreshActiveSearch: _searchQuery.trim().isNotEmpty,
    );
    notifyListeners();
  }

  List<Song> _normalizeImportedSongs(List<Song> songs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Song> normalized = [];
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      final id = song.id.isNotEmpty ? song.id : 'song_${now}_$i';
      normalized.add(
        Song(
          id: id,
          title: song.title.trim().isEmpty ? 'Untitled' : song.title.trim(),
          lyrics: song.lyrics?.trim(),
          lyricsEnglish: song.lyricsEnglish?.trim(),
          chords: song.chords?.trim(),
          pageNumber: song.pageNumber ?? i + 1,
          category: song.category ?? 'Worship',
          createdAt: song.createdAt,
        ),
      );
    }
    return normalized;
  }

  Future<String?> exportSelectedAsPDF() async {
    if (_selectedSongs.isEmpty) return null;
    return _pdfService.createPDFFromSongs(_selectedSongs);
  }

  Future<bool> shareExportedPdf(String filePath) async {
    return _pdfService.sharePdfFromPath(filePath);
  }

  void reorderSelected(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _selectedSongs.removeAt(oldIndex);
    _selectedSongs.insert(newIndex, item);
    _scheduleSaveSelected();
    notifyListeners();
  }
}
