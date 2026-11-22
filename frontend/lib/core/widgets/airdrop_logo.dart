import 'dart:math' as math;

import 'package:flutter/material.dart';

/// El ícono de AirDrop (Obsidiana): la ficha con el degradado pino →
/// pizarra → obsidiana, el dron jade visto desde arriba y la cruz de salud encima.
///
/// La geometría es la de `Airdrop_Products/_brand/logo/svg/airdrop-app-icon.svg`
/// (lienzo de 1024). Por debajo de 48 px el manual pide la versión simple
/// (ficha y cruz), porque los trazos del dron ya no se ven.
///
/// [rotorTurns] gira cada rotor sobre su propio eje (en vueltas), las
/// diagonales en sentidos opuestos, como en un dron real. El logo entero
/// nunca rota: el manual lo prohíbe (la cruz pasaría a ser una X).
class AirDropLogo extends StatelessWidget {
  const AirDropLogo({super.key, this.size = 48, this.rotorTurns = 0});

  final double size;
  final double rotorTurns;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo de AirDrop',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _AirDropLogoPainter(full: size >= 48, turns: rotorTurns),
      ),
    );
  }
}

/// Colores fijos del manual de marca: el logo no cambia con el tema.
abstract final class _Brand {
  static const pine = Color(0xFF1F3A3A);
  static const slate = Color(0xFF0B1214);
  static const obsidian = Color(0xFF070A0B);
  static const jade = Color(0xFF5EEAD4);
  static const cross = Color(0xFFFFFFFF);
}

class _AirDropLogoPainter extends CustomPainter {
  const _AirDropLogoPainter({required this.full, this.turns = 0});

  final bool full;

  /// Vueltas de cada rotor sobre su eje.
  final double turns;

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
          colors: [_Brand.pine, _Brand.slate, _Brand.obsidian],
          stops: [0, 0.6, 1],
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
      ..color = _Brand.jade
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
      // Los rotores 0 y 3 (una diagonal) giran a un lado; 1 y 2, al otro.
      final spin = (i == 0 || i == 3 ? 1 : -1) * turns * 2 * math.pi;
      final turn = _rotorTurn[i] * math.pi / 180 + spin;
      for (var start = 0.0; start < 2 * math.pi - 1e-6; start += period) {
        final sweep = math.min(dash, 2 * math.pi - start);
        canvas.drawArc(rect, turn + start, sweep, false, stroke);
      }
    }

    final hub = Paint()..color = _Brand.jade;
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
  bool shouldRepaint(_AirDropLogoPainter old) =>
      old.full != full || old.turns != turns;
}

/// El logo arrancando: los rotores giran unas vueltas y se detienen
/// despacio. Es la firma del arranque de la app. Con "reducir movimiento"
/// queda quieto desde el principio.
class LiveLogo extends StatefulWidget {
  const LiveLogo({super.key, this.size = 48, this.turns = 3});

  final double size;

  /// Cuántas vueltas da cada rotor antes de parar.
  final double turns;

  @override
  State<LiveLogo> createState() => _LiveLogoState();
}

class _LiveLogoState extends State<LiveLogo>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _spin.forward();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) => AirDropLogo(
        size: widget.size,
        // Arranca rápido y frena: termina en una vuelta entera, que es la
        // misma posición del logo quieto.
        rotorTurns: widget.turns * Curves.easeOutCubic.transform(_spin.value),
      ),
    );
  }
}
