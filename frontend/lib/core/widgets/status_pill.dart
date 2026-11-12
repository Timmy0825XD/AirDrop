import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';

/// Qué tan bien está lo que muestra la pastilla.
/// `neutral` va en el color de marca: algo que sigue su curso normal.
enum PillTone { positive, attention, negative, neutral }

/// Estado en una pastilla con punto (Activa, Suspendida, En vuelo…). El
/// color no es decorativo: distingue de un vistazo si algo puede operar.
/// Cuando cambia el texto, la pastilla nueva entra con un rebote corto.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final PillTone tone;

  /// El color de cada tono; lo comparten otras piezas (puntos, cifras).
  static Color colorOf(BuildContext context, PillTone tone) {
    final palette = context.palette;
    return switch (tone) {
      PillTone.positive => palette.success,
      PillTone.attention => palette.warning,
      PillTone.negative => palette.danger,
      PillTone.neutral => Theme.of(context).colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorOf(context, tone);
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.enter),
      switchInCurve: AppMotion.bounceCurve,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
