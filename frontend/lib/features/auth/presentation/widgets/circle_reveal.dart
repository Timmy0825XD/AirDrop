import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Capa del color de marca que crece en círculo desde [center] hasta cubrir
/// la pantalla. Es la salida del login hacia el inicio: el botón ya es un
/// círculo y desde ahí se expande.
class CircleReveal extends StatelessWidget {
  const CircleReveal({
    super.key,
    required this.progress,
    required this.center,
    this.startRadius = 29,
  });

  final Animation<double> progress;
  final Offset center;
  final double startRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) => progress.value == 0
            ? const SizedBox.shrink()
            : ClipPath(
                clipper: _CircleClipper(
                  center: center,
                  progress: progress.value,
                  startRadius: startRadius,
                ),
                child: child,
              ),
        child: ColoredBox(color: color, child: const SizedBox.expand()),
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper({
    required this.center,
    required this.progress,
    required this.startRadius,
  });

  final Offset center;
  final double progress;
  final double startRadius;

  @override
  Path getClip(Size size) {
    // El radio final llega a la esquina más lejana, así no queda borde.
    final far = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
          math.pow(math.max(center.dy, size.height - center.dy), 2),
    );
    final radius = startRadius + (far - startRadius) * progress;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.progress != progress || old.center != center;
}
