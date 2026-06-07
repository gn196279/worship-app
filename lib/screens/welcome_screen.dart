import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/google_icon.dart';
import 'auth_gate.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final UserPreferencesService _prefsService = UserPreferencesService();
  bool _isGoogleSigningIn = false;

  Future<void> _continueAsGuest() async {
    await _prefsService.setGuestMode(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  void _showGoogleSignInFeedback(Object error) {
    if (!mounted) return;

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'google-sign-in-cancelled':
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          AppSnackBar.info(context, 'Google sign-in cancelled.');
          return;
        case 'network-request-failed':
          AppSnackBar.warning(
            context,
            'Network issue. Please check your internet and try again.',
          );
          return;
        case 'too-many-requests':
          AppSnackBar.warning(
            context,
            'Too many attempts. Please wait and try again.',
          );
          return;
      }
    }

    final errorText = error.toString().toLowerCase();
    if (errorText.contains('cancel')) {
      AppSnackBar.info(context, 'Google sign-in cancelled.');
      return;
    }

    AppSnackBar.error(
        context, 'Unable to sign in with Google. Please try again.');
  }

  Future<void> _continueWithGoogle() async {
    if (_isGoogleSigningIn) return;
    setState(() => _isGoogleSigningIn = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      _showGoogleSignInFeedback(e);
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFFECC813);
    const lightBackground = Color(0xFFF8F8F6);
    const darkBackground = Color(0xFF221F10);
    const textDark = Color(0xFF1B190D);

    return Scaffold(
      backgroundColor: isDark ? darkBackground : lightBackground,
      body: Stack(
        children: [
          // Gradient background shown instantly — no blank screen while image loads.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF221F10)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC-rI_UAEzG1voJ76ZU_4eXuj-bidtrELUtNhxcGZsNyHwhYfW77OJ3GmAZFzsqHr6_LI-ikJBFltTMtoQN3640pegtim7LZPZ66033qzsWEnR48mLvQwCOhfvhMu8_-qZgJ4JSoCRiOyVp_gY9FIKLFI_99YM3jL7-D401-4sPfJZmVLucM2EIUQynAaDHS83sTNFW6Tyz_pHZYUN_vsLTA0iyEn4Op3UeIWiaz0aUk39s9HEoNhpqCgIUQj8zj2w_t-YtXEAa6CyW',
              fit: BoxFit.cover,
              // Show nothing (gradient shows through) while the image is downloading.
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox.shrink();
              },
              // On error (offline / slow network) the gradient background shows.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.library_music,
                            color: primary,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gilgal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Middle section
                  const Column(
                    children: [
                      Text(
                        'Welcome to Gilgal Worship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '\u0c17\u0c3f\u0c32\u0c4d\u0c17\u0c32\u0c4d \u0c06\u0c30\u0c3e\u0c27\u0c28 \u0c17\u0c40\u0c24\u0c3e\u0c32\u0c15\u0c41 \u0c38\u0c4d\u0c35\u0c3e\u0c17\u0c24\u0c02',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: 48,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x99ECC813),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Manage and search your Telugu worship song lists from uploaded PDFs effortlessly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  // Bottom section
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isGoogleSigningIn ? null : _continueWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: textDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isGoogleSigningIn
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GoogleIcon(size: 28),
                                    SizedBox(width: 10),
                                    Text(
                                      'Login with Google',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _continueAsGuest,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Continue as Guest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign in with Email',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        'Version 2.4.0 • Designed for Worship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
