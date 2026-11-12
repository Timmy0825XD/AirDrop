import 'package:flutter/widgets.dart';

/// Los colores del mapa dibujado del auth (no los tiles reales): tierra
/// cálida, parques, río y calles, como un mapa de ciudad común.
@immutable
class AppMapLook {
  const AppMapLook._({
    required this.ground,
    required this.park,
    required this.river,
    required this.road,
  });

  factory AppMapLook.of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static const _light = AppMapLook._(
    ground: Color(0xFFEFECE5),
    park: Color(0xFFD3E7CC),
    river: Color(0xFFB9DAEE),
    road: Color(0xFFFFFFFF),
  );

  static const _dark = AppMapLook._(
    ground: Color(0xFF17191B),
    park: Color(0xFF1F2C24),
    river: Color(0xFF1B3445),
    road: Color(0xFF2D3035),
  );

  final Color ground;
  final Color park;
  final Color river;
  final Color road;
}

/// Cómo se tiñen los tiles de OpenStreetMap para que el mapa combine con
/// la app sin pedir una clave de API: en oscuro se invierten a un gris
/// neutro (las calles quedan como trazos oscuros y los nombres claros); en
/// claro se desaturan un poco.
abstract final class AppMapStyle {
  /// Gris invertido y comprimido al fondo oscuro de la app, sin tinte.
  static const ColorFilter dark = ColorFilter.matrix([
    -0.190, -0.640, -0.065, 0, 250, //
    -0.190, -0.640, -0.065, 0, 252, //
    -0.190, -0.640, -0.065, 0, 256, //
    0, 0, 0, 1, 0,
  ]);

  /// Color al 30 % con un leve frío; los nombres siguen oscuros.
  static const ColorFilter light = ColorFilter.matrix([
    0.71, 0.21, 0.02, 0, 4, //
    0.06, 0.88, 0.02, 0, 6, //
    0.06, 0.21, 0.69, 0, 14, //
    0, 0, 0, 1, 0,
  ]);
}
