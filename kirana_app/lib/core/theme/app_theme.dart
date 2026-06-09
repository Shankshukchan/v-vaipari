import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF030213);
  static const Color primaryForeground = Colors.white;
  static const Color foreground = Color(0xFF223960);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color background = Colors.white;
  static const Color card = Colors.white;
  static const Color muted = Color(0xFFECECF0);
  static const Color mutedForeground = Color(0xFF717182);
  static const Color accent = Color(0xFFE9EBEF);
  static const Color destructive = Color(0xFFD4183D);
  static const Color border = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const Color inputBackground = Color(0xFFF3F3F5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: accent,
        onSecondary: primary,
        error: destructive,
        onError: Colors.white,
        background: background,
        onBackground: primary,
        surface: card,
        onSurface: primary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // radius: 0.625rem = 10px
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
