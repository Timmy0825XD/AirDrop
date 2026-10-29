import 'package:flutter/widgets.dart';

/// Cómo se tiñen los tiles de OpenStreetMap para que el mapa combine con
/// la app sin pedir una clave de API: en oscuro se invierten a grises y se
/// llevan al grafito con un velo turquesa (las calles quedan como trazos
/// oscuros y los nombres claros); en claro se desaturan hacia el cielo.
abstract final class AppMapStyle {
  /// Gris invertido, comprimido al grafito y teñido de turquesa.
  static const ColorFilter dark = ColorFilter.matrix([
    -0.180, -0.610, -0.062, 0, 236, //
    -0.196, -0.665, -0.067, 0, 262, //
    -0.204, -0.690, -0.070, 0, 274, //
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
