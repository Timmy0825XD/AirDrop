import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_backdrop.dart';
import 'app_palette.dart';

/// Paleta y tipografía de AirDrop, rediseño "natural": fondo cálido y liso,
/// superficies sólidas, un solo acento verde azulado y la fuente Figtree.
/// Es la única fuente de colores de la app: las pantallas leen
/// `Theme.of(context)` y `context.palette`, y nunca escriben hex.
class AppTheme {
  AppTheme._();

  /// Verde azulado de marca; en oscuro sube de luz para leerse sobre gris.
  static const Color primary = Color(0xFF0F6E6A);
  static const Color primaryOnDark = Color(0xFF5DBFB4);
  static const double radius = 16;

  static ThemeData get light => _build(
    const _Palette(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      sunk: Color(0xFFF3F1EC),
      line: Color(0xFFCFCBC3),
      ink: Color(0xFF1B1D1F),
      muted: Color(0xFF62676D),
      extra: AppPalette.light,
    ),
  );

  static ThemeData get dark => _build(
    const _Palette(
      brightness: Brightness.dark,
      primary: primaryOnDark,
      onPrimary: Color(0xFF10201F),
      surface: Color(0xFF222528),
      sunk: Color(0xFF2B2F33),
      line: Color(0xFF3D4247),
      ink: Color(0xFFF1F0EC),
      muted: Color(0xFFA6ABB0),
      extra: AppPalette.dark,
    ),
  );

  static ThemeData _build(_Palette p) {
    final base = ThemeData(brightness: p.brightness, useMaterial3: true);
    final font = GoogleFonts.figtree(color: p.ink);
    final x = p.extra;
    final colors =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: p.brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          secondary: x.warning,
          onSecondary: x.onAccent,
          tertiary: x.success,
          error: x.danger,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.muted,
          surfaceContainerHighest: p.sunk,
          outline: p.line,
          outlineVariant: x.glassBorder,
        );
    final text = _textTheme(base.textTheme, font, p.muted);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return base.copyWith(
      // El fondo lo pinta `AppBackdrop`; el scaffold queda transparente.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: p.surface,
      colorScheme: colors,
      extensions: [x],
      textTheme: text,
      iconTheme: IconThemeData(color: p.ink),
      inputDecorationTheme: _inputTheme(p),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const AppPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: shape,
          textStyle: font.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(0, 48),
          shape: shape,
          textStyle: font.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: p.line),
          shape: shape,
          textStyle: font.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: font.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        extendedTextStyle: font.copyWith(fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.muted.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      // El vidrio lo pinta `GlassSnack` (core/widgets/app_snack.dart).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentTextStyle: font.copyWith(
          color: p.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        titleTextStyle: text.titleLarge,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, TextStyle font, Color muted) {
    // Cifras de ancho fijo: los contadores no bailan al cambiar.
    const tabular = [FontFeature.tabularFigures()];
    TextStyle title(double size, {double spacing = -0.02}) => font.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: spacing * size,
      height: 1.08,
      fontFeatures: tabular,
    );
    TextStyle text(double size, FontWeight weight) =>
        font.copyWith(fontSize: size, fontWeight: weight);

    return base.copyWith(
      displayLarge: title(64, spacing: -0.03),
      displayMedium: title(48, spacing: -0.03),
      displaySmall: title(40),
      headlineLarge: title(32),
      headlineMedium: title(24),
      headlineSmall: title(20),
      titleLarge: text(20, FontWeight.w600),
      titleMedium: text(16, FontWeight.w600),
      titleSmall: text(14, FontWeight.w600),
      bodyLarge: text(16, FontWeight.w400),
      bodyMedium: text(15, FontWeight.w400),
      bodySmall: text(13, FontWeight.w400).copyWith(color: muted),
      labelLarge: text(14, FontWeight.w600),
      labelMedium: text(12, FontWeight.w600).copyWith(color: muted),
      // Rótulos de sección dentro de una tarjeta: escritos normal, en gris.
      labelSmall: text(13, FontWeight.w600).copyWith(color: muted),
    );
  }

  static InputDecorationTheme _inputTheme(_Palette p) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: p.extra.glass,
      border: border(p.extra.glassBorder),
      enabledBorder: border(p.extra.glassBorder),
      focusedBorder: border(p.primary, 1.6),
      errorBorder: border(p.extra.danger),
      focusedErrorBorder: border(p.extra.danger, 1.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.8)),
    );
  }
}

/// Los valores que cambian entre claro y oscuro.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.sunk,
    required this.line,
    required this.ink,
    required this.muted,
    required this.extra,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color sunk;
  final Color line;
  final Color ink;
  final Color muted;
  final AppPalette extra;
}
