import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';

/// Mini gráfico de barras: cada valor es una barra que crece desde abajo
/// al aparecer. La barra [highlight] va en el acento pleno; las demás, en
/// el acento tenue.
class BarSpark extends StatelessWidget {
  const BarSpark({
    super.key,
    required this.values,
    this.highlight,
    this.height = 64,
  });

  final List<int> values;
  final int? highlight;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accentGradient.first;
    final top = values.fold<int>(1, (max, v) => v > max ? v : max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.count),
      curve: AppMotion.enterCurve,
      builder: (context, t, _) => SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, v) in values.indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: (0.06 + 0.94 * v / top) * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i == highlight
                          ? accent
                          : accent.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
