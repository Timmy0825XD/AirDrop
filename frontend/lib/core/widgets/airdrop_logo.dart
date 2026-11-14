import 'dart:math' as math;

import 'package:flutter/material.dart';

/// El ícono de AirDrop (Dron-cruz): la ficha con el degradado turquesa →
/// petróleo, el dron visto desde arriba y la cruz de salud encima.
///
/// La geometría es la de `Airdrop_Products/_brand/logo/svg/airdrop-app-icon.svg`
/// (lienzo de 1024). Por debajo de 48 px el manual pide la versión simple
/// (ficha y cruz), porque los trazos del dron ya no se ven.
class AirDropLogo extends StatelessWidget {
  const AirDropLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo de AirDrop',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _AirDropLogoPainter(full: size >= 48),
      ),
    );
  }
}

/// Colores fijos del manual de marca: el logo no cambia con el tema.
abstract final class _Brand {
  static const teal = Color(0xFF159AA4);
  static const petrol = Color(0xFF0A4E58);
  static const mist = Color(0xFFBDEFED);
  static const cross = Color(0xFFFFFFFF);
}

class _AirDropLogoPainter extends CustomPainter {
  const _AirDropLogoPainter({required this.full});

  final bool full;

  static const _rotors = [
    Offset(327, 327),
    Offset(697, 327),
    Offset(327, 697),
    Offset(697, 697),
  ];

  /// Giro del trazo abierto de cada rotor (en grados), para que el hueco mire
  /// hacia fuera.
  static const _rotorTurn = [0.0, 90.0, 270.0, 180.0];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);
    const tile = Rect.fromLTWH(0, 0, 1024, 1024);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tile, const Radius.circular(229)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Brand.teal, _Brand.petrol],
        ).createShader(tile),
    );

    if (!full) {
      canvas
        ..translate(512, 512)
        ..scale(1.22)
        ..translate(-512, -512);
      _cross(canvas);
      return;
    }

    final stroke = Paint()
      ..color = _Brand.mist
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    const center = Offset(512, 512);
    for (final rotor in _rotors) {
      canvas.drawLine(center, rotor, stroke);
    }

    // Cada rotor es un círculo de radio 72 con trazo "170 56": un arco de
    // 170 px, un hueco de 56. En el SVG el trazo arranca a las 3 y avanza en
    // sentido horario; aquí se dibujan los mismos arcos.
    const radius = 72.0;
    const circumference = 2 * math.pi * radius;
    const dash = 170 / circumference * 2 * math.pi;
    const period = 226 / circumference * 2 * math.pi;
    for (var i = 0; i < _rotors.length; i++) {
      final rect = Rect.fromCircle(center: _rotors[i], radius: radius);
      final turn = _rotorTurn[i] * math.pi / 180;
      for (var start = 0.0; start < 2 * math.pi - 1e-6; start += period) {
        final sweep = math.min(dash, 2 * math.pi - start);
        canvas.drawArc(rect, turn + start, sweep, false, stroke);
      }
    }

    final hub = Paint()..color = _Brand.mist;
    for (final rotor in _rotors) {
      canvas.drawCircle(rotor, 18, hub);
    }
    _cross(canvas);
  }

  void _cross(Canvas canvas) {
    final paint = Paint()..color = _Brand.cross;
    canvas
      ..drawRRect(
        RRect.fromLTRBR(444, 322, 580, 702, const Radius.circular(38)),
        paint,
      )
      ..drawRRect(
        RRect.fromLTRBR(322, 444, 702, 580, const Radius.circular(38)),
        paint,
      );
  }

  @override
  bool shouldRepaint(_AirDropLogoPainter old) => old.full != full;
}
