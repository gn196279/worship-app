import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String favoritesKey = 'favorite_songs';
  static const String searchHistoryKey = 'search_history';
  static const String guestModeKey = 'guest_mode';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> addFavorite(String songId) async {
    final prefs = await _instance;
    final favorites = prefs.getStringList(favoritesKey) ?? [];
    if (!favorites.contains(songId)) {
      favorites.add(songId);
      await prefs.setStringList(favoritesKey, favorites);
    }
  }

  Future<void> removeFavorite(String songId) async {
    final prefs = await _instance;
    final favorites = prefs.getStringList(favoritesKey) ?? [];
    favorites.remove(songId);
    await prefs.setStringList(favoritesKey, favorites);
  }

  Future<List<String>> getFavorites() async {
    final prefs = await _instance;
    return prefs.getStringList(favoritesKey) ?? [];
  }

  Future<void> setFavorites(List<String> ids) async {
    final prefs = await _instance;
    await prefs.setStringList(favoritesKey, ids);
  }

  Future<void> addSearchQuery(String query) async {
    final prefs = await _instance;
    final history = prefs.getStringList(searchHistoryKey) ?? [];
    history.insert(0, query);
    // Keep only the latest 20 searches
    final limitedHistory = history.toSet().toList().take(20).toList();
    await prefs.setStringList(searchHistoryKey, limitedHistory);
  }

  Future<List<String>> getSearchHistory() async {
    final prefs = await _instance;
    return prefs.getStringList(searchHistoryKey) ?? [];
  }

  Future<void> clearSearchHistory() async {
    final prefs = await _instance;
    await prefs.remove(searchHistoryKey);
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await _instance;
    await prefs.setBool(guestModeKey, isGuest);
  }

  Future<bool> isGuestMode() async {
    final prefs = await _instance;
    return prefs.getBool(guestModeKey) ?? false;
  }
}
