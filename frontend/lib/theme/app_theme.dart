import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tipografía de AirDrop. Es la única fuente de colores de la app:
/// las pantallas leen `Theme.of(context)` y nunca escriben hex.
class AppTheme {
  AppTheme._();

  /// Verde azulado de marca. En oscuro se usa [primaryOnDark], el mismo tono
  /// aclarado para que contraste sobre el fondo casi negro.
  static const Color primary = Color(0xFF0B7A75);
  static const Color primaryOnDark = Color(0xFF68ADA9);

  /// Naranja de señal: el dron y lo que está en vuelo.
  static const Color signal = Color(0xFFE8743B);
  static const Color tertiary = Color(0xFF10B981);
  static const Color error = Color(0xFFC2362B);
  static const Color errorOnDark = Color(0xFFFF8C7F);
  static const double radius = 18;

  static ThemeData get light => _build(
        const _Palette(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Color(0xFFFFFFFF),
          error: error,
          background: Color(0xFFF5F6F3),
          surface: Color(0xFFFFFFFF),
          sunk: Color(0xFFECEEEA),
          line: Color(0xFFE2E6E1),
          ink: Color(0xFF101716),
          muted: Color(0xFF5D6A67),
        ),
      );

  static ThemeData get dark => _build(
        const _Palette(
          brightness: Brightness.dark,
          primary: primaryOnDark,
          onPrimary: Color(0xFF05201C),
          error: errorOnDark,
          background: Color(0xFF0B1110),
          surface: Color(0xFF141B1A),
          sunk: Color(0xFF0F1615),
          line: Color(0xFF25302E),
          ink: Color(0xFFEEF3F1),
          muted: Color(0xFF95A4A0),
        ),
      );

  static ThemeData _build(_Palette p) {
    final base = ThemeData(brightness: p.brightness, useMaterial3: true);
    final font = GoogleFonts.plusJakartaSans(color: p.ink);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      colorScheme: base.colorScheme.copyWith(
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: signal,
        onSecondary: Colors.white,
        tertiary: tertiary,
        error: p.error,
        surface: p.surface,
        onSurface: p.ink,
        onSurfaceVariant: p.muted,
        surfaceContainerHighest: p.sunk,
        outline: p.line,
      ),
      textTheme: _textTheme(base.textTheme, font, p.muted),
      inputDecorationTheme: _inputTheme(p),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: font.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, TextStyle font, Color muted) {
    // Titulares w800 con letter-spacing negativo, como en el diseño de auth.
    TextStyle title(double size) => font.copyWith(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03 * size,
          height: 1.1,
        );
    TextStyle text(double size, FontWeight weight) =>
        font.copyWith(fontSize: size, fontWeight: weight);

    return base.copyWith(
      displayLarge: title(40),
      displayMedium: title(32),
      headlineLarge: title(28),
      headlineMedium: title(22),
      titleLarge: text(20, FontWeight.w700),
      titleMedium: text(16, FontWeight.w700),
      titleSmall: text(14, FontWeight.w700),
      bodyLarge: text(16, FontWeight.w500),
      bodyMedium: text(14, FontWeight.w500),
      bodySmall: text(12, FontWeight.w500),
      labelLarge: text(13, FontWeight.w600).copyWith(color: muted),
      labelMedium: text(12, FontWeight.w600).copyWith(color: muted),
      // Labels de campo: mayúsculas con aire.
      labelSmall: text(11, FontWeight.w700)
          .copyWith(color: muted, letterSpacing: 1.3),
    );
  }

  static InputDecorationTheme _inputTheme(_Palette p) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: 1.5),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: border(p.line),
      enabledBorder: border(p.line),
      focusedBorder: border(p.primary),
      errorBorder: border(p.error),
      focusedErrorBorder: border(p.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.75)),
    );
  }
}

/// Los valores que cambian entre claro y oscuro.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.error,
    required this.background,
    required this.surface,
    required this.sunk,
    required this.line,
    required this.ink,
    required this.muted,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color error;
  final Color background;
  final Color surface;
  final Color sunk;
  final Color line;
  final Color ink;
  final Color muted;
}
