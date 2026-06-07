import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Smooth slide-from-right (Cupertino-style) transition applied on every platform.
const _smoothTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
  },
);

class AppTheme {
  static SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBackground,
      pageTransitionsTheme: _smoothTransitions,
      snackBarTheme: _snackBarTheme(colorScheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      pageTransitionsTheme: _smoothTransitions,
      snackBarTheme: _snackBarTheme(colorScheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
