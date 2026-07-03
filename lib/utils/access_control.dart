import '../models/user_role.dart';

/// Resolves UI and feature permissions for guest vs signed-in roles.
class AccessControl {
  final bool isGuest;
  final String role;

  const AccessControl({
    required this.isGuest,
    required this.role,
  });

  factory AccessControl.guest() =>
      const AccessControl(isGuest: true, role: UserRole.singer);

  factory AccessControl.from({
    required bool isGuestMode,
    String? firestoreRole,
  }) {
    if (isGuestMode) return AccessControl.guest();
    return AccessControl(
      isGuest: false,
      role: UserRole.normalize(firestoreRole),
    );
  }

  bool get isSinger => !isGuest && role == UserRole.singer;
  bool get isMusician => !isGuest && role == UserRole.musician;
  bool get isAdmin => !isGuest && role == UserRole.admin;

  bool get canBrowseAndSearch => true;
  bool get canViewLyrics => true;
  bool get canViewChords => isMusician || isAdmin;
  bool get canFavorite => true;
  bool get canShare => !isGuest;
  bool get canDownloadPdf => !isGuest;
  bool get canUsePlaylist => !isGuest;
  bool get canUpload => isMusician || isAdmin;
  bool get canEditSongs => isMusician || isAdmin;
  bool get canManageRoles => isAdmin;

  String get roleLabel =>
      isGuest ? 'Guest' : UserRole.label(role);

  int get songDetailTabCount => canViewChords ? 3 : 2;
}
