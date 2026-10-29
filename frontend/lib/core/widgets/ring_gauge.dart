import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';

/// Anillo de progreso con el acento en degradado. El arco se llena al
/// aparecer y se mueve suave cuando cambia [progress] (0 a 1).
class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.progress,
    this.size = 48,
    this.stroke = 4,
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final track = Theme.of(context).colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0, 1)),
      duration: AppMotion.of(context, AppMotion.count),
      curve: AppMotion.enterCurve,
      builder: (context, t, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          progress: t,
          stroke: stroke,
          track: track.withValues(alpha: 0.12),
          colors: palette.accentGradient,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.colors,
  });

  final double progress;
  final double stroke;
  final Color track;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress <= 0) return;
    // Un degradado lineal a lo largo del anillo: el de barrido no se pinta
    // en la versión web.
    paint
      ..color = colors.first
      ..shader = LinearGradient(colors: colors).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.colors != colors;
}
