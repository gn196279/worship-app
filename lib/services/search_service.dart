import 'dart:collection';
import '../models/song.dart';

class SearchService {
  // Pre-computed search indexes for fast lookup
  final Map<String, Set<String>> _titleIndex = {};
  final Map<String, Set<String>> _lyricsIndex = {};
  final Map<String, Set<String>> _lyricsEnglishIndex = {};

  // Prefix tries — only title and English lyrics use prefix search.
  // The Telugu lyrics trie (_lyricsTrie) was never queried with
  // isPrefixSearch:true, so we removed it. Building a trie over full
  // Telugu lyrics for 700 songs (thousands of nodes) was the single
  // largest contributor to the Android ANR dialogs.
  final TrieNode _titleTrie = TrieNode();
  final TrieNode _lyricsEnglishTrie = TrieNode();

  // Song lookup by ID
  final Map<String, Song> _songLookup = {};

  // Cache for recent searches
  final Map<String, List<Song>> _searchCache = {};
  static const int _maxCacheSize = 50;

  bool _isIndexed = false;

  /// Builds search indexes for all songs (synchronous — blocks the main thread).
  /// Prefer [buildIndexAsync] to keep the UI responsive.
  void buildIndex(List<Song> songs) {
    _clearIndexes();

    for (final song in songs) {
      _songLookup[song.id] = song;
      _indexSong(song);
    }

    _isIndexed = true;
    _searchCache.clear();
  }

  /// Builds the search index in small batches, yielding one frame between
  /// each batch so the UI thread is never blocked.
  ///
  /// Batch size is 20 (down from 100) so that even on the slowest devices
  /// no single CPU burst exceeds a few hundred milliseconds — preventing ANR.
  Future<void> buildIndexAsync(List<Song> songs) async {
    _clearIndexes();
    const batchSize = 4;
    for (int i = 0; i < songs.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, songs.length);
      for (int j = i; j < end; j++) {
        final song = songs[j];
        _songLookup[song.id] = song;
        _indexSong(song);
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }
    _isIndexed = true;
    _searchCache.clear();
  }

  /// Performs optimized search with prefix matching
  List<Song> search(String query, {int maxResults = 100}) {
    if (!_isIndexed) {
      return _songLookup.values.toList();
    }

    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) {
      return _songLookup.values.toList();
    }

    final cacheKey = '$normalizedQuery:$maxResults';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    final queryWords =
        normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

    final Set<String> matchingSongIds = {};

    // 1. Title prefix search — highest precision, always run
    matchingSongIds.addAll(_searchInIndex(
      _titleIndex,
      _titleTrie,
      queryWords,
      isPrefixSearch: true,
    ));

    // 2. English transliteration search — ALWAYS run, never gated.
    //    Critical: if user types in English, the Telugu title/lyrics won't
    //    match at all. Gating this behind a count check caused English
    //    searches to silently return nothing when the Telugu index flooded first.
    matchingSongIds.addAll(_searchInIndex(
      _lyricsEnglishIndex,
      _lyricsEnglishTrie,
      queryWords,
      isPrefixSearch: true,
    ));

    // 3. Telugu lyrics — exact/partial match using the inverted index only
    //    (no trie prefix search — the trie for full lyrics was removed because
    //    it was never queried with isPrefixSearch and was the main ANR source).
    if (matchingSongIds.length < maxResults * 2) {
      matchingSongIds.addAll(_searchInIndexOnly(_lyricsIndex, queryWords));
    }

    final results = matchingSongIds
        .map((id) => _songLookup[id])
        .where((song) => song != null)
        .cast<Song>()
        .toList();

    _sortSearchResults(results, normalizedQuery);

    final finalResults =
        results.length > maxResults ? results.sublist(0, maxResults) : results;

    _cacheSearchResult(cacheKey, finalResults);

    return finalResults;
  }

  void _sortSearchResults(List<Song> results, String normalizedQuery) {
    // Pre-compute once per song instead of on every sort comparison
    final titles = <String, String>{};
    final english = <String, String>{};
    for (final song in results) {
      titles[song.id] = _normalizeText(song.title);
      english[song.id] = _normalizeText(song.lyricsEnglish ?? '');
    }

    results.sort((a, b) {
      final aTitle = titles[a.id]!;
      final bTitle = titles[b.id]!;
      final aEng = english[a.id]!;
      final bEng = english[b.id]!;

      // Telugu title starts with query (highest priority)
      final aStartsWith = aTitle.startsWith(normalizedQuery);
      final bStartsWith = bTitle.startsWith(normalizedQuery);
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // English lyrics start with query (second priority)
      final aEngStartsWith = aEng.startsWith(normalizedQuery);
      final bEngStartsWith = bEng.startsWith(normalizedQuery);
      if (aEngStartsWith && !bEngStartsWith) return -1;
      if (!aEngStartsWith && bEngStartsWith) return 1;

      // Telugu title contains query anywhere
      final aContains = aTitle.contains(normalizedQuery);
      final bContains = bTitle.contains(normalizedQuery);
      if (aContains && !bContains) return -1;
      if (!aContains && bContains) return 1;

      // English lyrics contain query anywhere
      final aEngContains = aEng.contains(normalizedQuery);
      final bEngContains = bEng.contains(normalizedQuery);
      if (aEngContains && !bEngContains) return -1;
      if (!aEngContains && bEngContains) return 1;

      final aWordCount = aTitle.split(' ').length;
      final bWordCount = bTitle.split(' ').length;
      if (aWordCount != bWordCount) return aWordCount.compareTo(bWordCount);

      return a.title.compareTo(b.title);
    });
  }

  /// Search using both a trie (prefix) and an inverted index (exact/partial).
  Set<String> _searchInIndex(
    Map<String, Set<String>> index,
    TrieNode trie,
    List<String> queryWords, {
    bool isPrefixSearch = false,
  }) {
    final Set<String> results = {};
    for (final word in queryWords) {
      if (word.isEmpty) continue;
      if (isPrefixSearch) {
        results.addAll(trie.searchPrefix(word));
      }
      final exactMatches = index[word];
      if (exactMatches != null) {
        results.addAll(exactMatches);
      }
      if (word.length >= 3 && results.length < 50 && index.length < 1000) {
        _addPartialMatches(index, word, results);
      }
    }
    return results;
  }

  /// Search using the inverted index only (no trie) — used for Telugu lyrics
  /// where we never need prefix matching and the trie was too expensive to build.
  Set<String> _searchInIndexOnly(
    Map<String, Set<String>> index,
    List<String> queryWords,
  ) {
    final Set<String> results = {};
    for (final word in queryWords) {
      if (word.isEmpty) continue;
      final exactMatches = index[word];
      if (exactMatches != null) {
        results.addAll(exactMatches);
      }
      if (word.length >= 3 && results.length < 50 && index.length < 1000) {
        _addPartialMatches(index, word, results);
      }
    }
    return results;
  }

  void _addPartialMatches(
    Map<String, Set<String>> index,
    String word,
    Set<String> results,
  ) {
    int checkedCount = 0;
    const int maxKeysToCheck = 200;

    for (final entry in index.entries) {
      if (checkedCount >= maxKeysToCheck) break;
      checkedCount++;

      if (entry.key.contains(word)) {
        results.addAll(entry.value);
        if (results.length > 200) break;
      }
    }
  }

  void _indexSong(Song song) {
    final songId = song.id;

    // Title: inverted index + trie (for prefix search)
    for (final word in _extractWords(song.title)) {
      _addToIndex(_titleIndex, word, songId);
      _titleTrie.insert(word, songId);
    }

    // Telugu lyrics: inverted index only — no trie.
    // Building a trie over full lyrics for 700 songs is extremely expensive
    // (millions of node insertions) and was the main cause of ANR dialogs.
    if (song.lyrics?.isNotEmpty == true) {
      for (final word in _extractWords(song.lyrics!)) {
        _addToIndex(_lyricsIndex, word, songId);
      }
    }

    // English lyrics: inverted index + trie (for prefix search)
    if (song.lyricsEnglish?.isNotEmpty == true) {
      for (final word in _extractWords(song.lyricsEnglish!)) {
        _addToIndex(_lyricsEnglishIndex, word, songId);
        _lyricsEnglishTrie.insert(word, songId);
      }
    }
  }

  void _addToIndex(Map<String, Set<String>> index, String word, String songId) {
    index.putIfAbsent(word, () => HashSet<String>()).add(songId);
  }

  /// **COMPLETELY FIXED: Simplified regex pattern without complex escaping issues**
  List<String> _extractWords(String text) {
    if (text.isEmpty) return [];

    final normalized = _normalizeText(text);
    // Simple regex that matches any non-word character
    return normalized
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'''[-।॥,;:!?()[\]{}"']'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _cacheSearchResult(String key, List<Song> results) {
    if (_searchCache.length >= _maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }
    _searchCache[key] = results;
  }

  void _clearIndexes() {
    _titleIndex.clear();
    _lyricsIndex.clear();
    _lyricsEnglishIndex.clear();
    _titleTrie.clear();
    _lyricsEnglishTrie.clear();
    _songLookup.clear();
    _searchCache.clear();
    _isIndexed = false;
  }

  /// Updates a single song in the index. Rebuilds the tries so stale prefixes
  /// from the old version of the song never leak into search results.
  void updateSong(Song song) {
    if (!_isIndexed) return;

    // Remove the old entry from inverted indexes (but not tries — they don't
    // support fast removal; we rebuild them below).
    if (_songLookup.containsKey(song.id)) {
      _removeSongFromInvertedIndexes(song.id);
    }

    _songLookup[song.id] = song;
    _indexSong(song);
    _searchCache.clear();

    // Rebuild tries from scratch so no stale prefix nodes remain.
    // This is O(N·avgWordLen) but happens at most once per user edit,
    // which is an infrequent operation — negligible on 700 songs.
    _rebuildTries();
  }

  void _rebuildTries() {
    _titleTrie.clear();
    _lyricsEnglishTrie.clear();
    for (final song in _songLookup.values) {
      for (final word in _extractWords(song.title)) {
        _titleTrie.insert(word, song.id);
      }
      if (song.lyricsEnglish?.isNotEmpty == true) {
        for (final word in _extractWords(song.lyricsEnglish!)) {
          _lyricsEnglishTrie.insert(word, song.id);
        }
      }
    }
  }

  void _removeSongFromInvertedIndexes(String songId) {
    _songLookup.remove(songId);
    _removeFromIndexMap(_titleIndex, songId);
    _removeFromIndexMap(_lyricsIndex, songId);
    _removeFromIndexMap(_lyricsEnglishIndex, songId);
  }

  void _removeFromIndexMap(Map<String, Set<String>> index, String songId) {
    final keysToRemove = <String>[];
    for (final entry in index.entries) {
      entry.value.remove(songId);
      if (entry.value.isEmpty) keysToRemove.add(entry.key);
    }
    for (final key in keysToRemove) {
      index.remove(key);
    }
  }

  List<Song> getAllSongs() {
    return _songLookup.values.toList();
  }

  bool containsSong(String songId) {
    return _songLookup.containsKey(songId);
  }

  int get songCount => _songLookup.length;

  bool get isIndexed => _isIndexed;

  void clearCache() {
    _searchCache.clear();
  }

  void rebuildIndex() {
    final songs = _songLookup.values.toList();
    _clearIndexes();
    buildIndex(songs);
  }
}

/// Trie data structure for efficient prefix matching
class TrieNode {
  final Map<String, TrieNode> children = {};
  final Set<String> songIds = HashSet<String>();

  void insert(String word, String songId) {
    TrieNode current = this;
    current.songIds.add(songId);

    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      current.children.putIfAbsent(char, () => TrieNode());
      current = current.children[char]!;
      current.songIds.add(songId);
    }
  }

  Set<String> searchPrefix(String prefix) {
    TrieNode? current = this;

    for (int i = 0; i < prefix.length; i++) {
      final char = prefix[i];
      if (!current!.children.containsKey(char)) {
        return {};
      }
      current = current.children[char];
    }

    return current?.songIds ?? {};
  }

  bool contains(String word) {
    TrieNode? current = this;

    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      if (!current!.children.containsKey(char)) {
        return false;
      }
      current = current.children[char];
    }

    return current != null;
  }

  void clear() {
    children.clear();
    songIds.clear();
  }
}

/// Extension methods for SearchService
extension AdvancedSearch on SearchService {
  List<Song> searchAdvanced(String query, {int maxResults = 100}) {
    final phraseRegExp = RegExp(r'"([^"]*)"');
    final phraseMatches = phraseRegExp.allMatches(query);

    String cleanQuery = query.replaceAll(phraseRegExp, '').trim();
    final List<String> phrases = [];

    for (final match in phraseMatches) {
      if (match.group(1) != null && match.group(1)!.isNotEmpty) {
        phrases.add(match.group(1)!);
      }
    }

    if (phrases.isNotEmpty) {
      return _searchWithPhrases(phrases, cleanQuery, maxResults);
    }

    return search(query, maxResults: maxResults);
  }

  List<Song> _searchWithPhrases(
      List<String> phrases, String otherTerms, int maxResults) {
    final allResults = search(otherTerms, maxResults: maxResults * 2);

    return allResults
        .where((song) {
          final fullText =
              '${song.title} ${song.lyrics ?? ''} ${song.lyricsEnglish ?? ''}'
                  .toLowerCase();
          return phrases
              .every((phrase) => fullText.contains(phrase.toLowerCase()));
        })
        .take(maxResults)
        .toList();
  }
}
