import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import 'home_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _guestModeFuture;
  final UserPreferencesService _prefsService = UserPreferencesService();

  @override
  void initState() {
    super.initState();
    _guestModeFuture = _prefsService.isGuestMode();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, ({bool isLoading, bool isRoleReady, User? user})>(
      selector: (_, auth) => (
        isLoading: auth.isLoading,
        isRoleReady: auth.isRoleReady,
        user: auth.firebaseUser,
      ),
      builder: (context, state, _) {
        Widget destination;

        if (state.isLoading) {
          destination = const SplashScreen(key: ValueKey('splash'));
        } else if (state.user != null) {
          // Wait for Firestore role before HomeScreen — avoids singer fallback UI.
          if (!state.isRoleReady) {
            destination = const SplashScreen(key: ValueKey('role-loading'));
          } else {
            destination = const HomeScreen(key: ValueKey('home'));
          }
        } else {
          destination = FutureBuilder<bool>(
            future: _guestModeFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SplashScreen(key: ValueKey('splash'));
              }
              return snapshot.data == true
                  ? const HomeScreen(key: ValueKey('home'))
                  : const WelcomeScreen(key: ValueKey('welcome'));
            },
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: destination,
        );
      },
    );
  }
}
