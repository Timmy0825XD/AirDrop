import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

/// El dron de la marca en tres cuartos: cuerpo grafito con filos turquesa,
/// hélices girando y un vaivén lento de vuelo. Con "reducir movimiento"
/// queda quieto. Es la ilustración de los inicios (provisional hasta que
/// llegue el render).
class DroneArt extends StatefulWidget {
  const DroneArt({super.key, this.width = 240});

  final double width;

  @override
  State<DroneArt> createState() => _DroneArtState();
}

class _DroneArtState extends State<DroneArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    still ? _controller.stop() : _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = Size(widget.width, widget.width * 170 / 260);
    return Semantics(
      label: 'Dron de AirDrop',
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return CustomPaint(
            size: size,
            painter: DronePainter(
              palette: palette,
              spin: (t * 9) % 1,
              bob: math.sin(t * math.pi * 2),
            ),
          );
        },
      ),
    );
  }
}

/// Pinta el dron en un lienzo de 260 × 170 escalado al tamaño pedido.
class DronePainter extends CustomPainter {
  const DronePainter({required this.palette, this.spin = 0, this.bob = 0});

  final AppPalette palette;

  /// Giro de las aspas (0 a 1) y vaivén vertical (-1 a 1).
  final double spin;
  final double bob;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 260;
    canvas.scale(k);
    _shadow(canvas);
    canvas.translate(0, bob * 4);
    _props(canvas, const [Offset(62, 44), Offset(198, 44)], 40, 7, 0.4);
    _arms(canvas, const [
      (Offset(108, 76), Offset(64, 52)),
      (Offset(152, 76), Offset(196, 52)),
    ], 7);
    _motors(canvas, const [
      Rect.fromLTWH(56, 45, 12, 11),
      Rect.fromLTWH(192, 45, 12, 11),
    ]);
    _legs(canvas);
    _body(canvas);
    _arms(canvas, const [
      (Offset(100, 98), Offset(38, 116)),
      (Offset(160, 98), Offset(222, 116)),
    ], 9);
    _motors(canvas, const [
      Rect.fromLTWH(30, 106, 16, 15),
      Rect.fromLTWH(214, 106, 16, 15),
    ]);
    _props(canvas, const [Offset(38, 104), Offset(222, 104)], 46, 8, 0);
    _lights(canvas);
    _gimbal(canvas);
  }

  void _shadow(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: const Offset(130, 158),
      width: 184 - bob * 10,
      height: 18,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.shadow, palette.shadow.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  void _props(
    Canvas c,
    List<Offset> centers,
    double rx,
    double ry,
    double phase,
  ) {
    final disc = palette.droneMetal[2].withValues(alpha: 0.55);
    for (final center in centers) {
      final rect = Rect.fromCenter(
        center: center,
        width: rx * 2,
        height: ry * 2,
      );
      c.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              disc.withValues(alpha: 0.05),
              disc,
              disc.withValues(alpha: 0),
            ],
            stops: const [0, 0.7, 1],
          ).createShader(rect),
      );
      final a = (spin + phase) * math.pi * 2;
      final tip = Offset(math.cos(a) * rx, math.sin(a) * ry);
      c.drawLine(
        center - tip,
        center + tip,
        Paint()
          ..color = disc
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _arms(Canvas c, List<(Offset, Offset)> arms, double width) {
    for (final (from, to) in arms) {
      c.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.droneMetal[0], palette.droneMetal[1]],
          ).createShader(Rect.fromPoints(from, to).inflate(width)),
      );
    }
  }

  void _motors(Canvas c, List<Rect> motors) {
    for (final rect in motors) {
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              palette.droneMetal[1],
              palette.droneMetal[2],
              palette.droneMetal[1],
            ],
            stops: const [0, 0.45, 1],
          ).createShader(rect),
      );
    }
  }

  void _legs(Canvas c) {
    final leg = Paint()
      ..color = palette.droneMetal[1]
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c
      ..drawLine(const Offset(104, 112), const Offset(112, 134), leg)
      ..drawLine(const Offset(156, 112), const Offset(148, 134), leg)
      ..drawLine(const Offset(104, 136), const Offset(120, 136), leg)
      ..drawLine(const Offset(140, 136), const Offset(156, 136), leg);
  }

  void _body(Canvas c) {
    final shell = Path()
      ..moveTo(86, 80)
      ..cubicTo(90, 62, 170, 62, 174, 80)
      ..lineTo(178, 100)
      ..cubicTo(174, 116, 86, 116, 82, 100)
      ..close();
    c.drawPath(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.droneShell,
          stops: const [0, 0.55, 1],
        ).createShader(const Rect.fromLTRB(82, 62, 178, 116)),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final shine = Path()
      ..moveTo(98, 72)
      ..cubicTo(110, 64, 150, 64, 162, 72);
    c.drawPath(
      shine,
      stroke
        ..strokeWidth = 3
        ..color = palette.glassBorder,
    );
    final trim = Path()
      ..moveTo(84, 99)
      ..cubicTo(100, 111, 160, 111, 176, 99);
    final accent = palette.accentGradient.first;
    c
      ..drawPath(
        trim,
        stroke
          ..strokeWidth = 2.5
          ..color = accent,
      )
      ..drawLine(
        const Offset(118, 76),
        const Offset(142, 76),
        stroke..strokeWidth = 2,
      );
  }

  void _lights(Canvas c) {
    c
      ..drawCircle(
        const Offset(38, 122),
        2.5,
        Paint()..color = palette.accentGradient.first,
      )
      ..drawCircle(
        const Offset(222, 122),
        2.5,
        Paint()..color = palette.danger,
      );
  }

  void _gimbal(Canvas c) {
    const center = Offset(130, 114);
    final ball = Rect.fromCircle(center: center, radius: 12);
    c.drawCircle(
      center,
      12,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [palette.droneMetal[2], palette.droneShell[2]],
        ).createShader(ball),
    );
    final accent = palette.accentGradient.first;
    const lens = Offset(130, 115);
    c
      ..drawCircle(lens, 10, Paint()..color = accent.withValues(alpha: 0.18))
      ..drawCircle(lens, 5.5, Paint()..color = palette.droneShell[2])
      ..drawCircle(
        lens,
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent,
      )
      ..drawCircle(
        const Offset(128, 113),
        1.6,
        Paint()..color = palette.glassBorder,
      );
  }

  @override
  bool shouldRepaint(DronePainter old) =>
      old.spin != spin || old.bob != bob || old.palette != palette;
}
