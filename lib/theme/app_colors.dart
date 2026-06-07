import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF2B6CEE);

  // Backgrounds
  static const Color lightBackground = Color(0xFFF6F6F8);
  static const Color darkBackground = Color(0xFF101622);

  // Cards / surfaces
  static const Color lightCard = Color(0xFFF3F4F6);
  static const Color darkCard = Color(0xFF1F2937);

  // Input field backgrounds (search bar, form fields)
  static const Color lightInputBg = Color(0xFFF3F4F6);
  static const Color darkInputBg = Color(0xFF1F2937);
  static const Color lightInputBorder = Color(0xFFF0F2F5);
  static const Color darkInputBorder = Color(0xFF374151);

  // Suggestion list backgrounds
  static const Color lightSuggestionBg = Colors.white;
  static const Color darkSuggestionBg = Color(0xFF111827);
  static const Color lightSuggestionBorder = Color(0xFFF3F4F6);
  static const Color darkSuggestionBorder = Color(0xFF1F2937);

  // Text
  static const Color lightText = Color(0xFF0D121B);
  static const Color darkText = Colors.white;

  // Helper methods
  static Color textPrimary(bool isDark) => isDark ? darkText : lightText;
  static Color appBarBackground(bool isDark) =>
      isDark ? darkBackground : Colors.white;
  static Color cardBackground(bool isDark) => isDark ? darkCard : lightCard;
  static Color inputBackground(bool isDark) =>
      isDark ? darkInputBg : lightInputBg;
  static Color inputBorder(bool isDark) =>
      isDark ? darkInputBorder : lightInputBorder;
}

