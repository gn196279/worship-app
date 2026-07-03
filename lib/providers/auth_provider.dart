import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import '../services/user_role_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserRoleService _roleService;
  final UserPreferencesService _prefsService = UserPreferencesService();
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _roleSub;

  User? _firebaseUser;
  AppUser? _appUser;
  bool _authStateLoading = true;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;

  /// True while Firebase auth is resolving or Firestore role is loading.
  bool get isLoading =>
      _authStateLoading || (_firebaseUser != null && _appUser == null);

  /// True once Firestore role is available for the signed-in user.
  bool get isRoleReady => _firebaseUser == null || _appUser != null;

  AuthProvider({
    AuthService? authService,
    UserRoleService? roleService,
  })  : _authService = authService ?? AuthService(),
        _roleService = roleService ?? UserRoleService() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    await _roleSub?.cancel();
    _roleSub = null;
    _firebaseUser = user;
    _appUser = null;
    _authStateLoading = false;
    notifyListeners();

    if (user == null) return;

    try {
      await _prefsService.setGuestMode(false);
      final profile = await _roleService.getOrCreateUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );

      // Ignore stale auth events (e.g. rapid sign-out during load).
      if (_firebaseUser?.uid != user.uid) return;

      _appUser = profile;
      notifyListeners();

      _roleSub = _roleService.watchUser(user.uid).listen(
        (liveUser) {
          if (liveUser == null || _firebaseUser?.uid != user.uid) return;
          if (_appUser?.role != liveUser.role ||
              _appUser?.displayName != liveUser.displayName) {
            _appUser = liveUser;
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Role listener error: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to load user role: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<UserCredential> signInWithGoogle() => _authService.signInWithGoogle();

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _roleSub?.cancel();
    super.dispose();
  }
}
