import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MedLens AI brand theme.
class MedLensTheme {
  MedLensTheme._();

  // Brand colors
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF34A853);
  static const Color error = Color(0xFFEA4335);
  static const Color warning = Color(0xFFFBBC04);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          error: error,
          surface: surface,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
