import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../../core/widgets/drone_mark.dart';

/// La ruta de la misión, de la central al destino: punteada, con lo
/// recorrido luminoso y el dron encima. Con [progress] (0 a 1, sale de la
/// telemetría) el dron va en su punto real de la ruta; sin él, flota en
/// medio con una estela que corre, para decir "va en camino" sin inventar
/// la posición.
class MissionRoute extends StatefulWidget {
  const MissionRoute({super.key, required this.endLabel, this.progress});

  final String endLabel;
  final double? progress;

  @override
  State<MissionRoute> createState() => _MissionRouteState();
}

class _MissionRouteState extends State<MissionRoute>
    with SingleTickerProviderStateMixin {
  late final _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    still ? _flow.stop() : _flow.repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ends = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    return SizedBox(
      height: 82,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 18,
            child: _RouteCanvas(flow: _flow, progress: widget.progress),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Text('CENTRAL', style: ends),
                const Spacer(),
                Flexible(
                  child: Text(
                    widget.endLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ends,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La curva con su dron. El dron se ubica con la misma curva que se pinta.
class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas({required this.flow, required this.progress});

  final Animation<double> flow;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final metric = _route(box.biggest).computeMetrics().first;
        return AnimatedBuilder(
          animation: flow,
          builder: (context, _) {
            final at = progress ?? 0.5;
            final spot = metric.getTangentForOffset(metric.length * at)!;
            final bob = progress == null
                ? 3 * math.sin(flow.value * 2 * math.pi)
                : 0.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter(
                      metric: metric,
                      progress: progress,
                      flow: flow.value,
                      accent: colors.primary,
                      pending: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Positioned(
                  left: spot.position.dx - 18,
                  top: spot.position.dy - 22 + bob,
                  child: const DroneMark(size: 36),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// La curva de la central (abajo a la izquierda) al destino.
Path _route(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(6, h - 6)
    ..cubicTo(w * 0.3, h - 6, w * 0.38, h * 0.18, w * 0.55, h * 0.22)
    ..cubicTo(w * 0.72, h * 0.26, w * 0.8, h - 12, w - 6, h - 16);
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.metric,
    required this.progress,
    required this.flow,
    required this.accent,
    required this.pending,
  });

  final PathMetric metric;
  final double? progress;
  final double flow;
  final Color accent;
  final Color pending;

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
    // Con telemetría, lo recorrido; sin ella, la estela que corre.
    final p = progress;
    final head = length * (p ?? flow);
    final start = p == null ? math.max(0.0, head - 70) : 0.0;
    _beam(canvas, metric.extractPath(start, head), accent);
    final from = metric.getTangentForOffset(0)!.position;
    final to = metric.getTangentForOffset(length)!.position;
    canvas
      ..drawCircle(from, 4, Paint()..color = accent)
      ..drawCircle(
        to,
        4.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent,
      );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.flow != flow || old.progress != progress || old.metric != metric;
}

/// Un trazo luminoso: el brillo difuso y la línea encima.
void _beam(Canvas canvas, Path path, Color accent) {
  canvas
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    )
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
}
