import 'package:flutter/material.dart';

import '../../data/order_models.dart';
import '../order_format.dart';
import 'order_row_card.dart';
import 'order_status_chip.dart';
import 'watch_flight_button.dart';

/// Un pedido en "Mis pedidos": qué es, cuándo, su estado y el dron si ya
/// tiene uno. Debajo, "Ver vuelo" cuando hay vuelo que seguir.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final urgent = order.missionType == MissionType.emergency;
    final drone = order.assignment?.identifier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderRowCard(
          icon: urgent ? Icons.emergency_outlined : Icons.event_outlined,
          tone: urgent ? colors.error : colors.primary,
          title: order.medicationName,
          accent: '${order.missionType.label} · ${order.quantity} und.',
          detail: [
            formatBogota(order.createdAt),
            if (drone != null) 'Dron $drone',
          ].join(' · '),
          pill: OrderStatusChip(status: order.status),
          onTap: onTap,
        ),
        if (order.hasFlight) ...[
          const SizedBox(height: 8),
          WatchFlightButton(orderId: order.id),
        ],
      ],
    );
  }
}
