import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/user_preferences_service.dart';

/// Lightweight provider for favorite song IDs. Persists in background; UI updates instantly.
class FavoritesProvider extends ChangeNotifier {
  final UserPreferencesService _prefs = UserPreferencesService();
  Set<String> _ids = {};
  bool _loaded = false;

  Set<String> get favoriteIds => Set.unmodifiable(_ids);
  int get count => _ids.length;
  bool get isLoaded => _loaded;

  bool isFavorite(String songId) => _ids.contains(songId);

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    final list = await _prefs.getFavorites();
    // Only keep non-empty IDs so count is 0 when there are no real favorites
    final validIds = list.where((id) => id.trim().isNotEmpty).toList();
    _ids = validIds.toSet();
    // Persist cleaned list so we don't show wrong count from stale/empty entries
    if (validIds.length != list.length) {
      unawaited(_prefs.setFavorites(validIds));
    }
    _loaded = true;
    notifyListeners();
  }

  /// Toggle favorite; UI updates immediately, persist runs in background.
  void toggle(String songId) {
    if (_ids.contains(songId)) {
      _ids.remove(songId);
      unawaited(_prefs.removeFavorite(songId));
    } else {
      _ids.add(songId);
      unawaited(_prefs.addFavorite(songId));
    }
    notifyListeners();
  }

  void add(String songId) {
    if (_ids.contains(songId)) return;
    _ids.add(songId);
    unawaited(_prefs.addFavorite(songId));
    notifyListeners();
  }

  void remove(String songId) {
    if (!_ids.contains(songId)) return;
    _ids.remove(songId);
    unawaited(_prefs.removeFavorite(songId));
    notifyListeners();
  }

  /// Remove favorite IDs that are not in [validSongIds] (e.g. deleted songs). Call after songs load.
  Future<void> removeStaleIds(Set<String> validSongIds) async {
    final toRemove = _ids.where((id) => !validSongIds.contains(id)).toList();
    if (toRemove.isEmpty) return;
    for (final id in toRemove) {
      _ids.remove(id);
    }
    final list = _ids.toList();
    await _prefs.setFavorites(list);
    notifyListeners();
  }
}
