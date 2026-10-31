import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../airspace/drone_mark.dart';
import '../login/login_timeline.dart';

/// El avance del registro como un plan de vuelo: una ruta con tres puntos
/// (identidad, contacto y acceso). Cada grupo de datos que queda bien
/// enciende su punto y el dron avanza hasta él. Solo orienta: lo que se
/// exige al enviar lo valida la pantalla.
class RegisterFlightPlan extends StatelessWidget {
  const RegisterFlightPlan({super.key, required this.completed});

  /// Cuántos de los tres grupos ya están completos (0 a 3).
  final int completed;

  static const labels = ['Identidad', 'Contacto', 'Acceso'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Registro: $completed de 3 grupos completos',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: completed / 3),
              duration: const Duration(milliseconds: 700),
              curve: authSettle,
              builder: (context, progress, _) => LayoutBuilder(
                builder: (context, box) =>
                    _FlightPath(size: box.biggest, progress: progress),
              ),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 24),
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i < completed ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La ruta, sus puntos y el dron puesto en [progress] (0 a 1).
class _FlightPath extends StatelessWidget {
  const _FlightPath({required this.size, required this.progress});

  final Size size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final metric = _route(size).computeMetrics().first;
    final at = metric
        .getTangentForOffset(metric.length * progress.clamp(0, 1))!
        .position;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RoutePainter(
              metric: metric,
              progress: progress,
              done: colors.primary,
              pending: colors.outline,
              hole: colors.surface,
            ),
          ),
        ),
        Positioned(
          left: at.dx - 13,
          top: at.dy - 22,
          child: const DroneMark(size: 26),
        ),
      ],
    );
  }
}

/// Curva suave de izquierda a derecha, como una ruta planeada.
Path _route(Size size) {
  final w = size.width;
  return Path()
    ..moveTo(12, 30)
    ..cubicTo(w * 0.22, 14, w * 0.34, 36, w * 0.5, 24)
    ..cubicTo(w * 0.68, 12, w * 0.82, 14, w - 12, 26);
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.metric,
    required this.progress,
    required this.done,
    required this.pending,
    required this.hole,
  });

  final PathMetric metric;
  final double progress;
  final Color done;
  final Color pending;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final length = metric.length;
    final dash = Paint()
      ..color = pending
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var d = 0.0; d < length; d += 8) {
      canvas.drawPath(metric.extractPath(d, d + 3), dash);
    }
    canvas.drawPath(
      metric.extractPath(0, length * progress),
      Paint()
        ..color = done
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i <= 3; i++) {
      final reached = progress >= i / 3 - 0.01;
      final at = metric.getTangentForOffset(length * i / 3)!.position;
      canvas
        ..drawCircle(at, 4.5, Paint()..color = reached ? done : hole)
        ..drawCircle(
          at,
          4.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = reached ? done : pending,
        );
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.progress != progress || old.done != done || old.metric != metric;
}
