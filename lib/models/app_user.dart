class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.role,
    required this.createdAt,
    this.email,
    this.displayName,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      role: (data['role'] as String?) ?? 'user',
      createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

