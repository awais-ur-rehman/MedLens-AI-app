import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MedLens AI brand theme — dark, calm, trustworthy.
class MedLensTheme {
  MedLensTheme._();

  // ─────────────────────────── Palette ───────────────────────────────────────

  static const Color background   = Color(0xFF080C18); // near-black navy
  static const Color surface      = Color(0xFF0F1629); // dark navy card
  static const Color surfaceElev  = Color(0xFF151E35); // slightly lighter card
  static const Color primary      = Color(0xFF4F6EF7); // electric blue
  static const Color accent       = Color(0xFF7C3AED); // purple
  static const Color secondary    = Color(0xFF10B981); // emerald (success)
  static const Color error        = Color(0xFFEF4444); // red
  static const Color warning      = Color(0xFFF59E0B); // amber
  static const Color divider      = Color(0xFF1E2D52); // subtle border
  static const Color textPrimary  = Color(0xFFF1F5FF); // near-white
  static const Color textSecondary= Color(0xFF8899CC); // blue-grey
  static const Color textHint     = Color(0xFF445077); // dimmed blue-grey
  static const Color onPrimary    = Color(0xFFFFFFFF);
  static const Color cameraOverlay= Color(0xCC000000);

  // ─────────────────────────── Gradients ─────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F1E), Color(0xFF120A30)],
  );

  // ─────────────────────────── Severity ──────────────────────────────────────

  static Color severityColor(String? severity) => switch (severity) {
        'low'    => secondary,
        'medium' => warning,
        'high'   => error,
        _        => primary,
      };

  // ─────────────────────────── ThemeData ─────────────────────────────────────

  static ThemeData get lightTheme {
    final base       = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final textTheme  = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: ColorScheme.dark(
        surface: surface,
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        error: error,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w500,
        ),
        bodyLarge:  textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
        bodySmall:  textTheme.bodySmall?.copyWith(color: textHint),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: divider,
          disabledForegroundColor: textHint,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElev,
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
        hintStyle: GoogleFonts.inter(color: textHint, fontSize: 15),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: divider, thickness: 1, space: 1,
      ),

      // Bottom sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElev,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Chips (citation badges)
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElev,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElev,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Icon
      iconTheme: const IconThemeData(color: textSecondary, size: 24),
    );
  }
}
