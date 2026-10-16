import 'package:flutter/material.dart';

import '../../data/order_models.dart';
import '../order_format.dart';
import 'order_kind_chip.dart';
import 'order_status_chip.dart';
import 'watch_flight_button.dart';

/// Fila de un pedido en el historial: qué es, cuándo, su estado, el dron si
/// ya tiene uno y "Ver vuelo" cuando hay vuelo que seguir.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drone = order.assignment?.identifier;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.medicationName, style: theme.textTheme.titleMedium),
              Text(
                [formatBogota(order.createdAt), ?drone].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OrderStatusChip(status: order.status),
                  OrderKindChip(missionType: order.missionType),
                ],
              ),
              if (order.hasFlight) ...[
                const SizedBox(height: 8),
                WatchFlightButton(orderId: order.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
