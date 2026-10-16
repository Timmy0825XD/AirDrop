import 'package:flutter/material.dart';

/// Un check que se dibuja de punta a punta según [progress] (0 a 1). Lo
/// usan la casilla del consentimiento y el éxito del código.
class CheckMarkPainter extends CustomPainter {
  const CheckMarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.6,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // Trazo pensado en una grilla de 24 × 24, escalado al tamaño real.
    final s = size.width / 24;
    final tick = Path()
      ..moveTo(6.5 * s, 12.5 * s)
      ..lineTo(10.5 * s, 16.5 * s)
      ..lineTo(17.5 * s, 8 * s);
    final metric = tick.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0, 1)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(CheckMarkPainter old) =>
      old.progress != progress || old.color != color;
}
