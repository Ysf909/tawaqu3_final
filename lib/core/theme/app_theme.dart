import 'package:flutter/material.dart';

class AppTheme {
  static const Color accent = Color(0xFFF2B441); // golden accent
  static const Color darkBg = Color(0xFF121419);
  static const Color darkCard = Color(0xFF1A1E24);
  static const Color lightBg = Color(0xFFF6F7FB);
  static const Color lightCard = Colors.white;

  // ---------------- DARK THEME ----------------
  static ThemeData get darkTheme {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: darkCard,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white, // title + icons
        elevation: 0,
        centerTitle: true,
      ),

      cardColor: darkCard,
      iconTheme: const IconThemeData(color: Colors.white),

      // Elevated buttons (PrimaryButton, etc.)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black, // text on gold
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton (e.g. “Trade”, “Sign up” links)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton (Google / Apple / Facebook)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.4),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: accent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),

      inputDecorationTheme: _inputDecoration(dark: true),
    );
  }

  // ---------------- LIGHT THEME ----------------
  static ThemeData get lightTheme {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: lightCard,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      cardColor: lightCard,
      iconTheme: const IconThemeData(color: Colors.black87),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.4),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: accent,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
      ),

      inputDecorationTheme: _inputDecoration(dark: false),
    );
  }

  // ---------------- INPUTS ----------------
  static InputDecorationTheme _inputDecoration({required bool dark}) {
    const borderColor = accent;
    return InputDecorationTheme(
      filled: true,
      fillColor: dark ? darkCard : lightCard, // solid, no opacity tricks
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: accent, width: 1.6),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      labelStyle: const TextStyle(color: accent),
    );
  }
}
