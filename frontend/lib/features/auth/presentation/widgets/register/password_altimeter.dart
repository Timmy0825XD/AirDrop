import 'package:flutter/material.dart';

import '../login/login_timeline.dart';
import '../reset/reset_password_strength.dart';

/// La fuerza de la contraseña como un altímetro: ocho barras que suben, la
/// altura en metros y el nivel ("Crucero · Segura"). Usa [PasswordScore];
/// solo orienta, lo que se exige es `Validators.password`.
class PasswordAltimeter extends StatelessWidget {
  const PasswordAltimeter({super.key, required this.controller});

  final TextEditingController controller;

  static const _altitudes = ['En tierra', 'Despegando', 'Ascenso', 'Crucero'];
  static const _meters = [0, 30, 80, 120, 150];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final level = PasswordScore.of(controller.text);
        final (strength, color) = PasswordScore.look(theme.colorScheme, level);
        final altitude = _altitudes[level.clamp(0, 3)];
        return Semantics(
          label:
              'Fuerza de la contraseña: ${strength.isEmpty ? altitude : strength}',
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AltitudeBars(lit: level * 2, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strength.isEmpty ? altitude : '$altitude · $strength',
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ),
              _Meters(value: _meters[level], color: color),
            ],
          ),
        );
      },
    );
  }
}

/// Ocho barras de abajo hacia arriba; se encienden [lit] con [color].
class _AltitudeBars extends StatelessWidget {
  const _AltitudeBars({required this.lit, required this.color});

  final int lit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final off = Theme.of(context).colorScheme.outline.withValues(alpha: 0.6);
    return Column(
      children: [
        for (var i = 7; i >= 0; i--)
          AnimatedContainer(
            duration: Duration(milliseconds: 180 + 30 * i),
            curve: authSettle,
            width: 18,
            height: 4,
            margin: const EdgeInsets.only(top: 2.5),
            decoration: BoxDecoration(
              color: i < lit ? color : off,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

/// La altura en metros, que cuenta hasta el valor nuevo.
class _Meters extends StatelessWidget {
  const _Meters({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: authSettle,
      builder: (context, meters, _) =>
          Text('${meters.round()} m', style: style),
    );
  }
}
