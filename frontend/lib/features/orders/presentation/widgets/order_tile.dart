import 'package:flutter/material.dart';

import '../../../delivery/presentation/widgets/receive_order_button.dart';
import '../../data/order_models.dart';
import '../order_format.dart';
import 'order_row_card.dart';
import 'order_status_chip.dart';
import 'watch_flight_button.dart';

/// Un pedido en una lista ("Mis pedidos", "Traslados entrantes"): qué es,
/// cuándo, su estado y el dron si ya tiene uno. Debajo, "Recibir pedido"
/// si [canReceive] y "Ver vuelo" si [canWatch] y hay vuelo que seguir.
class OrderTile extends StatelessWidget {
  const OrderTile({
    super.key,
    required this.order,
    required this.onTap,
    this.canWatch = true,
    this.canReceive = false,
  });

  final Order order;
  final VoidCallback onTap;
  final bool canWatch;
  final bool canReceive;

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
        if (canReceive) ...[
          const SizedBox(height: 8),
          ReceiveOrderButton(orderId: order.id),
        ],
        if (canWatch && order.hasFlight) ...[
          const SizedBox(height: 8),
          WatchFlightButton(orderId: order.id),
        ],
      ],
    );
  }
}
