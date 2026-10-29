import 'package:flutter/material.dart';

/// Lo que el `ColorScheme` de Material no trae: el degradado del fondo, sus
/// resplandores, el vidrio, el degradado del acento y el semáforo completo.
/// Se lee con `context.palette`; nunca se escriben estos colores en una
/// pantalla.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.backdrop,
    required this.accentGlow,
    required this.skyGlow,
    required this.accentGradient,
    required this.onAccent,
    required this.glass,
    required this.glassBorder,
    required this.bar,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.mapTint,
    this.droneShell = const [
      Color(0xFF5A636B),
      Color(0xFF2B3136),
      Color(0xFF121517),
    ],
    this.droneMetal = const [
      Color(0xFF3A4248),
      Color(0xFF101315),
      Color(0xFF5A646C),
    ],
  });

  /// Arriba, en medio y abajo del degradado de fondo.
  final List<Color> backdrop;

  /// Velo turquesa (abajo a la derecha) y de cielo (arriba a la izquierda).
  final Color accentGlow;
  final Color skyGlow;

  /// El acento en degradado: botón central, chips activos, botón principal.
  final List<Color> accentGradient;
  final Color onAccent;

  /// Tarjetas de vidrio: relleno translúcido y borde fino.
  final Color glass;
  final Color glassBorder;

  /// La barra flotante y los paneles sobre el mapa: vidrio más opaco.
  final Color bar;
  final Color shadow;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Color con que se tiñen los tiles del mapa para que combinen.
  final Color mapTint;

  /// El cuerpo grafito del dron (arriba, medio, abajo) y su metal (brazo
  /// claro, brazo oscuro, brillo del motor). Iguales en los dos modos.
  final List<Color> droneShell;
  final List<Color> droneMetal;

  LinearGradient get accent => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: accentGradient,
  );

  static const dark = AppPalette(
    backdrop: [Color(0xFF1F2A30), Color(0xFF14191D), Color(0xFF0B0E10)],
    accentGlow: Color(0x334FC3C9),
    skyGlow: Color(0x1FBFD2E2),
    accentGradient: [Color(0xFF6ED6D9), Color(0xFF3FA9C0)],
    onAccent: Color(0xFF071214),
    glass: Color(0x12FFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    bar: Color(0xE6161C20),
    shadow: Color(0x66000000),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF6A),
    danger: Color(0xFFFF8FA3),
    info: Color(0xFFA9C8E6),
    mapTint: Color(0xFF14191D),
  );

  static const light = AppPalette(
    backdrop: [Color(0xFFF7FAFC), Color(0xFFE3EDF4), Color(0xFFCFDFEB)],
    accentGlow: Color(0x4D4FC3C9),
    skyGlow: Color(0x52BFD2E2),
    accentGradient: [Color(0xFF137C8A), Color(0xFF0B6470)],
    onAccent: Color(0xFFFFFFFF),
    glass: Color(0x9EFFFFFF),
    glassBorder: Color(0xF2FFFFFF),
    bar: Color(0xE0FFFFFF),
    shadow: Color(0x1A142832),
    success: Color(0xFF116632),
    warning: Color(0xFF9A4A06),
    danger: Color(0xFFA82D24),
    info: Color(0xFF2F5F8A),
    mapTint: Color(0xFFE3EDF4),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> l(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], b[i]),
    ];
    return AppPalette(
      backdrop: l(backdrop, other.backdrop),
      accentGlow: c(accentGlow, other.accentGlow),
      skyGlow: c(skyGlow, other.skyGlow),
      accentGradient: l(accentGradient, other.accentGradient),
      onAccent: c(onAccent, other.onAccent),
      glass: c(glass, other.glass),
      glassBorder: c(glassBorder, other.glassBorder),
      bar: c(bar, other.bar),
      shadow: c(shadow, other.shadow),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      info: c(info, other.info),
      mapTint: c(mapTint, other.mapTint),
      droneShell: l(droneShell, other.droneShell),
      droneMetal: l(droneMetal, other.droneMetal),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
