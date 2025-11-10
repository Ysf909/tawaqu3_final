import 'package:flutter/material.dart';

class AppTheme {
  static const Color accent = Color(0xFFF2B441); // golden accent
  static const Color darkBg = Color(0xFF121419);
  static const Color darkCard = Color(0xFF1A1E24);
  static const Color lightBg = Color(0xFFF6F7FB);
  static const Color lightCard = Colors.white;

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
        ),
        inputDecorationTheme: _inputDecoration(dark: true),
        cardColor: darkCard,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData.light().copyWith(
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: accent,
          secondary: accent,
        ),
        inputDecorationTheme: _inputDecoration(dark: false),
        cardColor: lightCard,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  static InputDecorationTheme _inputDecoration({required bool dark}) {
    final borderColor = accent.withOpacity(0.7);
    return InputDecorationTheme(
      filled: true,
      fillColor: (dark ? darkCard : lightCard).withOpacity(0.4),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accent, width: 1.6),
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: TextStyle(color: accent.withOpacity(0.9)),
    );
  }
}

