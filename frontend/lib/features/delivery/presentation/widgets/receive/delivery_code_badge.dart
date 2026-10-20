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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('TU CÓDIGO DE ENTREGA', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            code.split('').join(' '),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: hurry ? colors.error : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
