import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Un número que cuenta desde 0 hasta [value] al aparecer, y desde el
/// valor anterior cuando cambia. Con "reducir movimiento" se muestra
/// directo. `null` pinta un guion: el dato todavía no llegó o falló.
class CountUpText extends StatelessWidget {
  const CountUpText({super.key, required this.value, this.style});

  final int? value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final target = value;
    if (target == null) return Text('—', style: style);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$target', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: AppMotion.count,
      curve: AppMotion.enterCurve,
      builder: (context, t, _) => Text('${t.round()}', style: style),
    );
  }
}
