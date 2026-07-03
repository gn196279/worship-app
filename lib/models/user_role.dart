/// App roles stored in Firestore `users/{uid}.role`.
class UserRole {
  UserRole._();

  static const String singer = 'singer';
  static const String musician = 'musician';
  static const String admin = 'admin';

  /// Legacy value — treated as [singer].
  static const String legacyUser = 'user';

  static const List<String> all = [singer, musician, admin];

  static String normalize(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return singer;
    if (value == legacyUser) return singer;
    if (all.contains(value)) return value;
    return singer;
  }

  static String label(String? raw) {
    switch (normalize(raw)) {
      case musician:
        return 'Musician';
      case admin:
        return 'Admin';
      default:
        return 'Singer';
    }
  }
}
