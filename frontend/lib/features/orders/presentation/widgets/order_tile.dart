import 'package:flutter/material.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_icons.dart';
import '../../../delivery/presentation/widgets/receive_order_button.dart';
import '../../data/order_models.dart';
import '../order_format.dart';
import 'order_row_card.dart';
import 'order_status_chip.dart';
import 'watch_flight_button.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({
    super.key,
    required this.order,
    required this.onTap,
    this.canWatch = true,
    this.canReceive = false,
    this.forRequester = false,
  });
  final Order order;
  final VoidCallback onTap;
  final bool canWatch, canReceive, forRequester;
  @override
  Widget build(BuildContext context) => OrderRowCard(
    icon: AppIcons.medication,
    tone: Theme.of(context).colorScheme.primary,
    title: order.medicationName,
    accent:
        '${unitsLabel(order.quantity)} · ${order.destinationKind == DestinationKind.hub ? 'Traslado entre centrales' : 'Para una persona'}',
    detail: [
      'Creado ${formatAgo(order.createdAt)}',
      if (order.assignment case final a?) 'Dron ${a.identifier}',
    ].join(' · '),
    pill: canReceive
        ? const StatusPill(
            label: 'Listo para recibir',
            tone: PillTone.attention,
          )
        : OrderStatusChip(status: order.status, forRequester: forRequester),
    footer: canReceive
        ? ReceiveOrderButton(
            orderId: order.id,
            landed: true,
            icon: AppIcons.deliveryCode,
          )
        : canWatch && order.hasFlight && order.status != OrderStatus.returning
        ? WatchFlightButton(orderId: order.id, icon: AppIcons.flight)
        : null,
    onTap: onTap,
    children: [
      if (order.requiresColdChain)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Cadena de frío'),
        ),
      if (order.statusReason case final reason?)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(reason, style: Theme.of(context).textTheme.bodySmall),
        ),
    ],
  );
}
