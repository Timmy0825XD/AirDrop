import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/tone_tile.dart';
import '../../../../orders/data/order_models.dart';

/// El pedido que está volando, arriba de todo: qué va en el dron, en qué
/// va y el atajo al mapa en vivo.
class FlightSpotlightCard extends StatelessWidget {
  const FlightSpotlightCard({
    super.key,
    required this.order,
    required this.onWatch,
  });

  final Order order;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ToneTile.icon(
              icon: Icons.near_me_rounded,
              tone: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.status.label.toUpperCase(),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.medicationName} · ${order.quantity} und.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onWatch, child: const Text('Ver mapa')),
          ],
        ),
      ),
    );
  }
}
