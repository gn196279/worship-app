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

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;

  void _setSignedInUserForUi(User user) {
    _firebaseUser = user;
    _isLoading = false;
    notifyListeners();
    unawaited(_prefsService.setGuestMode(false));
  }

  AuthProvider({
    AuthService? authService,
    UserRoleService? roleService,
  })  : _authService = authService ?? AuthService(),
        _roleService = roleService ?? UserRoleService(),
        _isLoading = false {
    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      // Session is immediately available — no loading needed.
      _firebaseUser = currentUser;
      _isLoading = false;
      unawaited(_prefsService.setGuestMode(false));
      unawaited(
        _roleService
            .getOrCreateUser(
          uid: currentUser.uid,
          email: currentUser.email,
          displayName: currentUser.displayName,
        )
            .then((u) {
          _appUser = u;
          notifyListeners();
        }).catchError((e) {
          debugPrint('Failed to load user role: $e');
        }),
      );
    } else {
      // Firebase is initialised but the session hasn't been confirmed yet.
      // Keep loading=true until authStateChanges fires so the UI never
      // flashes the WelcomeScreen before we know the real auth state.
      _isLoading = true;
    }

    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    _appUser = null;
    _isLoading = false;
    notifyListeners();

    if (user == null) return;

    unawaited(_prefsService.setGuestMode(false));
    unawaited(
      _roleService
          .getOrCreateUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      )
          .then((loadedUser) {
        _appUser = loadedUser;
        notifyListeners();
      }).catchError((e) {
        debugPrint('Failed to load user role: $e');
      }),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    final user = credential.user;
    if (user != null) {
      _setSignedInUserForUi(user);
    }
    return credential;
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> sendSignInOtp(String email) => _authService.sendSignInOtp(email);

  Future<UserCredential> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    final credential = await _authService.signInWithEmailLink(email, emailLink);
    final user = credential.user;
    if (user != null) {
      _setSignedInUserForUi(user);
    }
    return credential;
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final credential = await _authService.signUpWithEmail(email, password);
    final user = credential.user;
    if (user != null) {
      _setSignedInUserForUi(user);
    }
    return credential;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _authService.signInWithEmail(email, password);
    final user = credential.user;
    if (user != null) {
      _setSignedInUserForUi(user);
    }
    return credential;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
