import 'package:flutter/material.dart';

/// Colores del login derivados del tema, para no poner hex en las pantallas.
/// Claro y oscuro salen del mismo `ColorScheme`.
class LoginPalette {
  const LoginPalette._({
    required this.dark,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.glassTop,
    required this.glassBottom,
    required this.border,
    required this.gloss,
    required this.field,
    required this.fieldBorder,
    required this.shadow,
    required this.btn1,
    required this.btn2,
    required this.btnText,
    required this.error,
    required this.success,
    required this.orbs,
  });

  factory LoginPalette.of(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final dark = c.brightness == Brightness.dark;
    Color white(double a) => Colors.white.withValues(alpha: a);
    Color deep(Color base, double t) => Color.lerp(base, Colors.black, t)!;
    final accent = dark ? c.secondary : deep(c.primary, 0.38);

    return LoginPalette._(
      dark: dark,
      ink: c.onSurface,
      muted: c.onSurface.withValues(alpha: dark ? 0.68 : 0.72),
      accent: accent,
      glassTop: white(dark ? 0.10 : 0.62),
      glassBottom: white(dark ? 0.04 : 0.38),
      border: white(dark ? 0.16 : 0.90),
      gloss: white(dark ? 0.30 : 0.95),
      field: white(dark ? 0.06 : 0.70),
      fieldBorder: dark ? white(0.28) : c.onSurface.withValues(alpha: 0.5),
      shadow: dark
          ? Colors.black.withValues(alpha: 0.5)
          : accent.withValues(alpha: 0.25),
      btn1: dark ? c.secondary : deep(c.primary, 0.32),
      btn2: dark ? c.primary : deep(c.primary, 0.5),
      btnText: dark ? c.onSecondary : Colors.white,
      error: dark ? c.error : deep(c.error, 0.35),
      success: dark ? c.tertiary : deep(c.tertiary, 0.45),
      orbs: [c.primary, c.tertiary, c.secondary],
    );
  }

  final bool dark;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color glassTop;
  final Color glassBottom;
  final Color border;
  final Color gloss;
  final Color field;
  final Color fieldBorder;
  final Color shadow;
  final Color btn1;
  final Color btn2;
  final Color btnText;
  final Color error;
  final Color success;
  final List<Color> orbs;
}