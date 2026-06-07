import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // Sign out Firebase first so authStateChanges emits immediately and UI
    // transitions to AuthGate/Welcome without waiting for Google APIs.
    final firebaseSignOut = _auth.signOut();
    if (!kIsWeb) {
      unawaited(_googleSignIn.signOut().catchError((_) => null));
    }
    await firebaseSignOut;
  }

  // Email link (OTP) authentication
  Future<void> sendSignInOtp(String email) async {
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: 'https://my-worship-app-2cf1e.firebaseapp.com',
        handleCodeInApp: true,
        iOSBundleId: 'com.example.gilgalTeluguWorship',
        androidPackageName: 'com.example.gilgal_telugu_worship',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      ),
    );
  }

  Future<UserCredential> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    if (_auth.isSignInWithEmailLink(emailLink)) {
      return _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    }
    throw FirebaseAuthException(
      code: 'invalid-email-link',
      message: 'The provided link is not a valid sign-in link.',
    );
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }
}
