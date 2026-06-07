import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/song.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/song_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_initializer.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent bars so the app background shows through edge-to-edge.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const GilgalApp());
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  await Hive.openBox<Song>('songs');
  await Hive.openBox<List>('selectedSongs');
}

class GilgalApp extends StatefulWidget {
  const GilgalApp({super.key});

  @override
  State<GilgalApp> createState() => _GilgalAppState();
}

class _GilgalAppState extends State<GilgalApp> {
  bool _initialized = false;
  bool _initError = false;

  // Themes built once — avoids running ColorScheme.fromSeed() on every build.
  static final _lightTheme = AppTheme.lightTheme();
  static final _darkTheme = AppTheme.darkTheme();

  // ThemeProvider lives outside the init gate so the MaterialApp is ALWAYS
  // themed correctly, even during the splash phase. It reads SharedPreferences
  // which is pre-warmed by _init(), and defaults to ThemeMode.system until then.
  final _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    // Defer heavy init to the first frame so the splash paints immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      // All three run in parallel: Firebase restores the auth token, Hive opens
      // boxes, SharedPreferences pre-warms the cache for every provider.
      await Future.wait([
        _initHive(),
        FirebaseInitializer.initialize(),
        SharedPreferences.getInstance(),
      ]);
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── All providers live ABOVE MaterialApp so every Navigator route ────────
    // (including pages pushed via Navigator.push) can read them.
    //
    // ThemeProvider: created immediately — only needs SharedPreferences.y

    // The other three use lazy create: (Provider's default) so their
    // constructors only run the first time a widget reads them. That first
    // read happens inside AuthGate, which is only shown after _initialized
    // is true — i.e. Hive boxes are open and Firebase is ready.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<FavoritesProvider>(
            create: (_) => FavoritesProvider()),
        ChangeNotifierProvider<SongProvider>(create: (_) => SongProvider()),
      ],
      child: Selector<ThemeProvider, ThemeMode>(
        selector: (_, t) => t.themeMode,
        builder: (_, themeMode, __) => MaterialApp(
          title: 'Gilgal Worship App',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 220),
          themeAnimationCurve: Curves.easeOutCubic,
          home: _buildHome(),
        ),
      ),
    );
  }

  Widget _buildHome() {
    if (_initError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'Could not start the app.\nPlease restart and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Hive / Firebase not ready yet — SplashScreen never touches the lazy
    // providers so their constructors don't run yet.
    if (!_initialized) return const SplashScreen();

    // Init complete. AuthGate is the first widget to read AuthProvider /
    // SongProvider / FavoritesProvider, triggering their lazy creation.
    return const AuthGate();
  }
}
