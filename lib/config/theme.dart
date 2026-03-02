import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MedLens AI brand theme.
///
/// Design philosophy: calm, professional, trustworthy.
/// A medical app that feels reassuring — not flashy.
class MedLensTheme {
  MedLensTheme._();

  // ──────────────────────────── Brand Palette ────────────────────────────

  /// Trust blue — primary actions, links, active states.
  static const Color primary = Color(0xFF1A73E8);

  /// Health green — success states, "healthy" indicators.
  static const Color secondary = Color(0xFF34A853);

  /// Severity red — errors, high-severity badges, destructive actions.
  static const Color error = Color(0xFFEA4335);

  /// Caution yellow — warnings, medium-severity badges.
  static const Color warning = Color(0xFFFBBC04);

  /// Pure white surface for cards and sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle warm grey background — softer than pure white.
  static const Color background = Color(0xFFF8F9FA);

  /// Semi-transparent black for camera overlay regions.
  static const Color cameraOverlay = Color(0xCC000000);

  /// Text on light backgrounds.
  static const Color textPrimary = Color(0xFF202124);

  /// Secondary / muted text.
  static const Color textSecondary = Color(0xFF5F6368);

  /// Hint / disabled text.
  static const Color textHint = Color(0xFF9AA0A6);

  /// Divider / border colour.
  static const Color divider = Color(0xFFDADCE0);

  /// White — used for text on coloured surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ────────────────────────── Severity Helpers ───────────────────────────

  /// Map severity string → colour.
  static Color severityColor(String? severity) => switch (severity) {
        'low' => secondary,
        'medium' => warning,
        'high' => error,
        _ => primary,
      };

  // ─────────────────────────── Light Theme ───────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      // Colour system
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        error: error,
        surface: surface,
        onSurface: textPrimary,
        brightness: Brightness.light,
      ),

      // Scaffold
      scaffoldBackgroundColor: background,

      // Typography
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: textHint),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // AppBar — transparent, no elevation, clean.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Elevated buttons — full-width, 56px, rounded, bold.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: divider,
          disabledForegroundColor: textHint,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined buttons — same shape, outlined.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards — subtle elevation, rounded.
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input fields.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textHint),
      ),

      // Dividers.
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom sheets.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Chips — used for citation badges.
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Snackbar.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Icon.
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
    );
  }
}
