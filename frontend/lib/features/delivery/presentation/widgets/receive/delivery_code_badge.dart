import 'package:flutter/material.dart';

/// El código de entrega en grande y, debajo, [caption]: que el dron va en
/// camino o cuánto falta para que venza. Con [hurry] la línea va en rojo.
class DeliveryCodeBadge extends StatelessWidget {
  const DeliveryCodeBadge({
    super.key,
    required this.code,
    required this.caption,
    this.hurry = false,
  });

  final String code;
  final String caption;
  final bool hurry;

  /// `4:05`: minutos y segundos.
  static String clock(Duration d) {
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text('Tu código de entrega', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code.split('').join(' '),
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 38,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: hurry ? colors.error : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
