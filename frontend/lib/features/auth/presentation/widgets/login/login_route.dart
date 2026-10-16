import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../drone_glyph.dart';
import 'login_timeline.dart';

/// La firma de AirDrop: la ruta curva de la central al destino.
///
/// En el splash se dibuja y el dron la cruza; ya en el encabezado, un punto
/// naranja la recorre en bucle para mostrar que el sistema está vivo.
class LoginRoute extends StatelessWidget {
  const LoginRoute({
    super.key,
    required this.timeline,
    required this.loop,
    required this.layout,
    this.opacity,
  });

  static const double height = 170;

  final LoginTimeline timeline;
  final Animation<double> loop;
  final LoginLayout layout;

  /// Al volver del registro la ruta reaparece con este fundido.
  final Animation<double>? opacity;

  @override
  Widget build(BuildContext context) {
    final travel = layout.routeSplashTop - layout.routeTop;
    final canvas = LayoutBuilder(
      builder: (context, constraints) => _RouteCanvas(
        metric: _routeMetric(constraints.maxWidth),
        timeline: timeline,
        loop: loop,
      ),
    );
    return Positioned(
      left: 24,
      right: 24,
      top: layout.routeTop,
      height: height,
      child: AnimatedBuilder(
        animation: timeline.morph,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, travel * (1 - timeline.morph.value)),
          child: child,
        ),
        child: opacity == null
            ? canvas
            : FadeTransition(opacity: opacity!, child: canvas),
      ),
    );
  }
}

/// Coloca a [child] sobre la ruta en [progress] (0 a 1), centrado. Se mueve
/// con `Transform`, así el dron viaja sin recalcular el layout.
Widget _onRoute(PathMetric metric, double progress, double size, Widget child) {
  final tangent = metric.getTangentForOffset(
    metric.length * progress.clamp(0, 1),
  );
  final at = (tangent?.position ?? Offset.zero) - Offset(size / 2, size / 2);
  return Align(
    alignment: Alignment.topLeft,
    child: Transform.translate(offset: at, child: child),
  );
}

/// El trazo del diseño (lienzo de 342 px de ancho), escalado al ancho real.
PathMetric _routeMetric(double width) {
  final s = width / 342;
  final path = Path()
    ..moveTo(28 * s, 132)
    ..cubicTo(118 * s, 132, 150 * s, 46, 300 * s, 44);
  return path.computeMetrics().first;
}

class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas({
    required this.metric,
    required this.timeline,
    required this.loop,
  });

  final PathMetric metric;
  final LoginTimeline timeline;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RoutePainter(
                metric: metric,
                draw: timeline.trip,
                color: colors.onPrimary,
                hole: colors.primary,
              ),
              foregroundPainter: _PinPainter(
                end: metric.getTangentForOffset(metric.length)!.position,
                scale: timeline.pin,
                color: colors.onPrimary,
                hole: colors.primary,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: _TripDrone(metric: metric, timeline: timeline),
        ),
        Positioned.fill(
          child: _LoopDot(metric: metric, loop: loop),
        ),
        const _RouteLabel(text: 'CENTRAL', left: 8, top: 148),
        const _RouteLabel(text: 'DESTINO', right: 4, top: 68),
      ],
    );
  }
}

/// El dron que cruza la ruta durante el splash y se desvanece con el morph.
class _TripDrone extends StatelessWidget {
  const _TripDrone({required this.metric, required this.timeline});

  final PathMetric metric;
  final LoginTimeline timeline;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timeline.controller,
      builder: (context, child) {
        final t = timeline.trip.value;
        final fade = (t * 16).clamp(0.0, 1.0) * (1 - timeline.morph.value);
        if (fade == 0) return const SizedBox.shrink();
        return _onRoute(metric, t, 34, Opacity(opacity: fade, child: child));
      },
      child: DroneGlyph(color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}

/// Punto naranja con pulso que recorre la ruta en bucle tras el splash.
/// Viaja el 72 % del ciclo y luego se apaga en el destino.
class _LoopDot extends StatelessWidget {
  const _LoopDot({required this.metric, required this.loop});

  final PathMetric metric;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final t = loop.value;
        if (t == 0) return const SizedBox.shrink();
        final travel = Curves.easeInOutCubic.transform((t / 0.72).clamp(0, 1));
        final fade = t < 0.08 ? t / 0.08 : (t < 0.72 ? 1.0 : (0.86 - t) / 0.14);
        return _onRoute(
          metric,
          travel,
          16,
          Opacity(opacity: fade.clamp(0, 1), child: child),
        );
      },
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
          border: Border.all(color: colors.onPrimary, width: 3),
          boxShadow: [
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLabel extends StatelessWidget {
  const _RouteLabel({
    required this.text,
    required this.top,
    this.left,
    this.right,
  });

  final String text;
  final double top;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Ruta punteada de fondo, el trazo que se dibuja y la central.
class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.metric,
    required this.draw,
    required this.color,
    required this.hole,
  }) : super(repaint: draw);

  final PathMetric metric;
  final Animation<double> draw;
  final Color color;

  /// El centro de la central: el verde de marca.
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (var d = 0.0; d < metric.length; d += 10) {
      canvas.drawPath(metric.extractPath(d, d + 3), line);
    }

    final progress = draw.value.clamp(0.0, 1.0);
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      line
        ..color = color
        ..strokeWidth = 2.5,
    );

    final start = metric.getTangentForOffset(0)!.position;
    canvas
      ..drawCircle(start, 7, Paint()..color = color)
      ..drawCircle(start, 3, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.metric != metric || old.color != color || old.hole != hole;
}

/// El pin del destino; crece desde su punta.
class _PinPainter extends CustomPainter {
  _PinPainter({
    required this.end,
    required this.scale,
    required this.color,
    required this.hole,
  }) : super(repaint: scale);

  final Offset end;
  final Animation<double> scale;
  final Color color;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale.value;
    if (s <= 0) return;
    final x = end.dx;
    final top = end.dy - 14;
    final tip = Offset(x, end.dy + 16);
    final drop = Path()
      ..moveTo(x, top)
      ..cubicTo(x - 7, top, x - 12, top + 5, x - 12, top + 11.5)
      ..cubicTo(x - 12, top + 20, x, tip.dy, x, tip.dy)
      ..cubicTo(x, tip.dy, x + 12, top + 20, x + 12, top + 11.5)
      ..cubicTo(x + 12, top + 5, x + 7, top, x, top);
    canvas
      ..save()
      ..translate(tip.dx, tip.dy)
      ..scale(s)
      ..translate(-tip.dx, -tip.dy)
      ..drawPath(drop, Paint()..color = color)
      ..drawCircle(Offset(x, top + 11.5), 4, Paint()..color = hole)
      ..restore();
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.end != end || old.color != color || old.hole != hole;
}
