import 'package:flutter/material.dart';

import '../auth_brand.dart';

/// Curva de asentamiento: arranca rápido y llega sin rebote, como un
/// resorte críticamente amortiguado.
const Curve authSettle = Cubic(0.2, 0.9, 0.25, 1);

/// Curva de los cambios grandes de forma: acelera y frena con firmeza.
const Curve authEmphasized = Cubic(0.65, 0, 0.2, 1);

/// La coreografía del login en un solo [AnimationController].
///
/// Cada pieza lee su tramo con un [Interval], así una sola animación mueve
/// todo sin `setState` y sin reconstruir la pantalla:
///
/// 1. Entrada (0–3,3 s): se encienden las centrales y la red sobre el
///    mapa, el dron llega desde abajo, el nombre aparece letra por letra
///    (de borroso a nítido) y luego el eslogan.
/// 2. Morph (3,3–4,6 s): el mapa se encoge hasta ser el encabezado y se
///    inclina en 3D, el dron viaja a la esquina como logo, empiezan a
///    volar los drones y la hoja del formulario sube.
class LoginTimeline {
  LoginTimeline(this.controller);

  static const Duration total = Duration(milliseconds: 4600);

  /// Punto en que termina la entrada. Tocar la pantalla salta hasta aquí.
  static const double morphStart = 3300 / 4600;

  final AnimationController controller;

  late final Animation<double> network = _span(0, 1400, Curves.easeOutCubic);
  late final Animation<double> logoPop = _span(450, 1550, authSettle);
  late final Animation<double> tagline = _span(1650, 2250, authSettle);
  late final Animation<double> hint = _span(2500, 2900, Curves.easeOut);
  late final Animation<double> morph = _span(3300, 4350, authEmphasized);
  late final Animation<double> traffic = _span(3300, 4500, Curves.easeOutCubic);
  late final Animation<double> form = _span(3650, 4600, authSettle);

  /// Cada letra de "AirDrop" entra 60 ms después de la anterior.
  late final List<Animation<double>> _letters = List.generate(
    7,
    (i) => _span(1050 + 60.0 * i, 1750 + 60.0 * i, authSettle),
  );

  Animation<double> letter(int index) => _letters[index];

  Animation<double> _span(double fromMs, double toMs, Curve curve) {
    final ms = total.inMilliseconds;
    return CurvedAnimation(
      parent: controller,
      curve: Interval(fromMs / ms, toMs / ms, curve: curve),
    );
  }
}

/// Medidas del login para una pantalla dada. El diseño se hizo a 390 × 844;
/// aquí las posiciones se calculan con el tamaño real y el área segura.
class LoginLayout {
  const LoginLayout({required this.size, required this.topInset});

  final Size size;
  final double topInset;

  /// Esquina superior izquierda del logo cuando ya es encabezado.
  Offset get logoCorner => Offset(24, AuthHeaderMetrics.brandTop(topInset));

  /// Centro del dron durante la entrada.
  Offset get logoSplashCenter => Offset(size.width / 2, size.height * 0.36);
}
