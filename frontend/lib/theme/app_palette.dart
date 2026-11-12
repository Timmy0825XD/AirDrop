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

  // Rediseño natural: fondo liso (las tres paradas son el mismo color, sin
  // velos), tarjetas sólidas y el acento sin degradado. Se conservan los
  // campos para que las piezas que aún los leen sigan funcionando.
  static const dark = AppPalette(
    backdrop: [Color(0xFF17191B), Color(0xFF17191B), Color(0xFF17191B)],
    accentGlow: Color(0x00000000),
    skyGlow: Color(0x00000000),
    accentGradient: [Color(0xFF5DBFB4), Color(0xFF5DBFB4)],
    onAccent: Color(0xFF10201F),
    glass: Color(0xFF222528),
    glassBorder: Color(0xFF363A3F),
    bar: Color(0xFF222528),
    shadow: Color(0x66000000),
    success: Color(0xFF6FCF97),
    warning: Color(0xFFE8B45A),
    danger: Color(0xFFF0958E),
    info: Color(0xFF8FB4D6),
    mapTint: Color(0xFF17191B),
  );

  static const light = AppPalette(
    backdrop: [Color(0xFFF5F4F1), Color(0xFFF5F4F1), Color(0xFFF5F4F1)],
    accentGlow: Color(0x00000000),
    skyGlow: Color(0x00000000),
    accentGradient: [Color(0xFF0F6E6A), Color(0xFF0F6E6A)],
    onAccent: Color(0xFFFFFFFF),
    glass: Color(0xFFFFFFFF),
    glassBorder: Color(0xFFE6E3DD),
    bar: Color(0xFFFFFFFF),
    shadow: Color(0x141B1D1F),
    success: Color(0xFF177A45),
    warning: Color(0xFF8F5200),
    danger: Color(0xFFB3261E),
    info: Color(0xFF2F5F8A),
    mapTint: Color(0xFFEFECE5),
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
