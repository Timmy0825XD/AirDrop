import 'package:flutter/material.dart';

import '../auth_brand.dart';

/// La coreografía del login en un solo [AnimationController].
///
/// Cada pieza lee su tramo con un [Interval], así una sola animación mueve
/// todo sin `setState` y sin reconstruir la pantalla:
///
/// 1. Splash (0–3,7 s): el logo aparece, el nombre entra letra por letra,
///    la ruta se dibuja y el dron la cruza hasta el destino.
/// 2. Morph (3,7–4,8 s): el bloque verde se encoge hasta ser el
///    encabezado curvo, el logo viaja a la esquina y el formulario sube.
class LoginTimeline {
  LoginTimeline(this.controller);

  static const Duration total = Duration(milliseconds: 4800);

  /// Punto en que termina el splash. Tocar la pantalla salta hasta aquí.
  static const double morphStart = 3700 / 4800;

  final AnimationController controller;

  late final Animation<double> logoPop = _span(120, 800, Curves.easeOutBack);
  late final Animation<double> tagline = _span(520, 1120, Curves.fastOutSlowIn);
  late final Animation<double> trip = _span(1100, 3100, Curves.easeInOutCubic);
  late final Animation<double> pin = _span(3000, 3620, Curves.easeOutBack);
  late final Animation<double> morph = _span(3700, 4650, Curves.easeInOutCubic);
  late final Animation<double> form = _span(4200, 4800, Curves.fastOutSlowIn);

  /// Cada letra de "AirDrop" entra 55 ms después de la anterior.
  late final List<Animation<double>> _letters = List.generate(
    7,
    (i) => _span(420 + 55.0 * i, 980 + 55.0 * i, Curves.easeOutBack),
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

  /// Centro del logo durante el splash.
  Offset get logoSplashCenter => Offset(size.width / 2, size.height * 0.37);

  double get routeTop => topInset + 84;
  double get routeSplashTop => logoSplashCenter.dy + 170;
}
