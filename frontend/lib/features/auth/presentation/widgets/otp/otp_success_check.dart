import 'package:flutter/material.dart';

import '../check_mark.dart';

/// El círculo verde con el check que reemplaza a las cajas del código. Crece
/// con un rebote mientras las cajas se juntan y luego el check se dibuja.
class OtpSuccessCheck extends StatelessWidget {
  const OtpSuccessCheck({super.key, required this.progress});

  static const double size = 72;

  /// La misma animación de 1250 ms que junta las cajas.
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value;
          if (t < 0.3) return const SizedBox.shrink();
          // Tramos: aparecer (380–580 ms), crecer (420–1040), check (820–1240).
          final appear = ((t - 0.30) / 0.16).clamp(0.0, 1.0);
          final grow = Curves.easeOutBack.transform(
            ((t - 0.34) / 0.5).clamp(0, 1),
          );
          final tick = Curves.easeInOutCubic.transform(
            ((t - 0.66) / 0.33).clamp(0, 1),
          );
          return Opacity(
            opacity: appear,
            child: Transform.scale(
              scale: 0.3 + 0.7 * grow,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: CheckMarkPainter(
                    progress: tick,
                    color: colors.onPrimary,
                    strokeWidth: 3.6,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
