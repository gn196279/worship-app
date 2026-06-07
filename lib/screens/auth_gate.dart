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
    return Selector<AuthProvider, ({bool isLoading, User? user})>(
      selector: (_, auth) => (isLoading: auth.isLoading, user: auth.firebaseUser),
      builder: (context, state, _) {
        // Resolve the actual destination widget.
        Widget destination;

        if (state.isLoading) {
          // Auth state not yet known — show the same SplashScreen that was
          // visible during Hive/Firebase init. The transition is invisible
          // because the pixels are identical (no flash, no jump).
          destination = const SplashScreen(key: ValueKey('splash'));
        } else if (state.user != null) {
          destination = const HomeScreen(key: ValueKey('home'));
        } else {
          destination = FutureBuilder<bool>(
            future: _guestModeFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                // Guest-mode preference still loading — keep the splash.
                return const SplashScreen(key: ValueKey('splash'));
              }
              return snapshot.data == true
                  ? const HomeScreen(key: ValueKey('home'))
                  : const WelcomeScreen(key: ValueKey('welcome'));
            },
          );
        }

        // AnimatedSwitcher gives a smooth fade when the destination changes
        // (e.g. SplashScreen → HomeScreen once auth is confirmed).
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

