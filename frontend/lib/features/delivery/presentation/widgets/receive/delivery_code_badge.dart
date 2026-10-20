import 'package:flutter/material.dart';

/// El código de entrega en grande y lo que falta para que venza. En el
/// último minuto la cuenta pasa a rojo.
class DeliveryCodeBadge extends StatelessWidget {
  const DeliveryCodeBadge({
    super.key,
    required this.code,
    required this.remaining,
  });

  final String code;
  final Duration remaining;

  /// `4:05`: minutos y segundos.
  static String clock(Duration d) {
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hurry = remaining.inSeconds < 60;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('TU CÓDIGO', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          SelectableText(
            code.split('').join(' '),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vence en ${clock(remaining)}',
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
