import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/tone_tile.dart';

/// Tarjeta de una bandeja de pedidos o planes: ícono teñido, título con
/// la pastilla de estado debajo, una línea de color y una gris, y la
/// flecha. A la izquierda, una franja del color del pedido que se apaga
/// hacia abajo, como la luz de estado de un tablero. Toda la tarjeta abre el detalle y se hunde al tocarla.
class OrderRowCard extends StatelessWidget {
  const OrderRowCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.accent,
    required this.detail,
    required this.onTap,
    this.pill,
  });

  final IconData icon;
  final Color tone;
  final String title;

  /// La línea en color (cantidad, destino, frecuencia).
  final String accent;

  /// La línea gris (stock, fecha).
  final String detail;
  final VoidCallback onTap;
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToneEdge(tone: tone),
            const SizedBox(width: 10),
            ToneTile.icon(icon: icon, tone: tone),
            const SizedBox(width: 12),
            Expanded(child: _Lines(card: this)),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.card});

  final OrderRowCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          card.accent,
          style: theme.textTheme.bodySmall?.copyWith(
            color: card.tone,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(card.detail, style: theme.textTheme.bodySmall),
        if (card.pill case final pill?) ...[const SizedBox(height: 10), pill],
      ],
    );
  }
}

/// La franja de color del borde izquierdo, con un brillo suave.
class _ToneEdge extends StatelessWidget {
  const _ToneEdge({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone, tone.withValues(alpha: 0.05)],
        ),
        boxShadow: [
          BoxShadow(color: tone.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
    );
  }
}
