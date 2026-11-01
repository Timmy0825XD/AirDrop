import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Un radar de adorno: anillos y cruz finos del acento y un barrido que
/// gira despacio. No marca nada: da la sensación de un sistema vigilando
/// el espacio aéreo. Con "reducir movimiento" queda quieto, sin barrido.
class RadarSweep extends StatefulWidget {
  const RadarSweep({
    super.key,
    this.period = const Duration(seconds: 4),
    this.reach = 0.5,
  });

  /// Lo que tarda una vuelta del barrido.
  final Duration period;

  /// El radio del anillo de afuera, en fracción del ancho. Con más de 0,5
  /// los anillos se salen por arriba y abajo, como en una pantalla de
  /// radar recortada.
  final double reach;

  @override
  State<RadarSweep> createState() => _RadarSweepState();
}

class _RadarSweepState extends State<RadarSweep>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: widget.period);
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _still ? _turn.stop() : _turn.repeat();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RadarPainter(
            turn: _turn,
            accent: Theme.of(context).colorScheme.primary,
            sweep: !_still,
            reach: widget.reach,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.turn,
    required this.accent,
    required this.sweep,
    required this.reach,
  }) : super(repaint: turn);

  final Animation<double> turn;
  final Color accent;
  final bool sweep;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * reach;
    canvas.clipRect(Offset.zero & size);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.16);
    for (final k in const [0.35, 0.68, 1.0]) {
      canvas.drawCircle(center, radius * k, line);
    }
    canvas
      ..drawLine(center - Offset(radius, 0), center + Offset(radius, 0), line)
      ..drawLine(center - Offset(0, radius), center + Offset(0, radius), line);
    if (!sweep) return;
    final angle = turn.value * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      angle - 0.9,
      0.9,
      true,
      Paint()
        ..shader = SweepGradient(
          endAngle: 0.9,
          colors: [accent.withValues(alpha: 0), accent.withValues(alpha: 0.28)],
          transform: GradientRotation(angle - 0.9),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.accent != accent || old.sweep != sweep;
}
