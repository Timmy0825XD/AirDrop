import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/tone_tile.dart';

/// Tarjeta de una bandeja de pedidos o planes: ícono teñido del color del
/// pedido, título, una línea de color y una gris, la pastilla de estado y
/// la flecha. Toda la tarjeta abre el detalle y se hunde al tocarla.
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
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToneTile.icon(icon: icon, tone: tone, size: 42),
          const SizedBox(width: 12),
          Expanded(child: _Lines(card: this)),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
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
        Text(
          card.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          card.accent,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: card.tone,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          card.detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        if (card.pill case final pill?) ...[const SizedBox(height: 8), pill],
      ],
    );
  }
}
