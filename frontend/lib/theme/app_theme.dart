import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF06B6D4);
  static const Color secondary = Color(0xFF22D3EE);
  static const Color tertiary = Color(0xFF10B981);
  static const Color error = Color(0xFFE5484D);
  static const double radius = 18;

  static const Color _darkBackground = Color(0xFF0A0E14);
  static const Color _darkSurface = Color(0xFF141A21);
  static const Color _darkTextPrimary = Color(0xFFEAF0F5);
  static const Color _darkTextSecondary = Color(0xFF8B98A5);

  static const Color _lightBackground = Color(0xFFF5F7FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF10151B);
  static const Color _lightTextSecondary = Color(0xFF5B6672);

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: _darkBackground,
        surface: _darkSurface,
        textPrimary: _darkTextPrimary,
        textSecondary: _darkTextSecondary,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: _lightBackground,
        surface: _lightSurface,
        textPrimary: _lightTextPrimary,
        textSecondary: _lightTextSecondary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final headlineFont = GoogleFonts.plusJakartaSans(color: textPrimary);
    final bodyFont = GoogleFonts.inter(color: textPrimary);
    final labelFont = GoogleFonts.inter(color: textSecondary);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: error,
        onSecondary: Colors.black, // texto/iconos sobre el botón cyan
        onSurface: textPrimary,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge:
            headlineFont.copyWith(fontWeight: FontWeight.w700, fontSize: 40),
        displayMedium:
            headlineFont.copyWith(fontWeight: FontWeight.w700, fontSize: 32),
        headlineLarge:
            headlineFont.copyWith(fontWeight: FontWeight.w600, fontSize: 28),
        headlineMedium:
            headlineFont.copyWith(fontWeight: FontWeight.w600, fontSize: 22),
        titleLarge:
            headlineFont.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium:
            headlineFont.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall:
            headlineFont.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: bodyFont.copyWith(fontSize: 16),
        bodyMedium: bodyFont.copyWith(fontSize: 14),
        bodySmall: bodyFont.copyWith(fontSize: 12),
        labelLarge:
            labelFont.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
        labelMedium: labelFont.copyWith(fontSize: 12),
        labelSmall: labelFont.copyWith(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(radius)),
          textStyle: bodyFont.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
