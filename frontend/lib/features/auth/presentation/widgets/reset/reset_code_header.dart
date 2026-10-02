import 'package:flutter/material.dart';

/// Encabezado del bloque de código: qué hacer con el código recibido y
/// cuánto falta para poder pedir uno nuevo.
class ResetCodeHeader extends StatelessWidget {
  const ResetCodeHeader({
    super.key,
    required this.secondsRemaining,
    required this.countdownLabel,
  });

  final int secondsRemaining;
  final String countdownLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final expired = secondsRemaining == 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Código de verificación',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!expired)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: colors.onSurface),
              const SizedBox(width: 4),
              Text(
                countdownLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          )
        else
          Text(
            'Puedes reenviarlo',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}