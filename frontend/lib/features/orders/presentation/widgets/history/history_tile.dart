import 'package:flutter/material.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../dispatcher_order_alerts.dart';
import '../dispatcher_order_card.dart';
import '../order_fact_row.dart';
import '../order_status_chip.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.order, required this.onOpen});
  final Order order;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final returned = order.status == OrderStatus.returned;
    final tone = returned
        ? PillTone.attention
        : OrderStatusChip.toneOf(order.status);
    return DispatcherOrderCard(
      title: order.medicationName,
      subtitle: '${unitsLabel(order.quantity)} · ${destinationLabel(order)}',
      status: StatusPill(
        label: order.status.label,
        tone: tone,
        wrapLabel: true,
        leading: Icon(
          returned
              ? AppIcons.undo
              : order.status == OrderStatus.delivered
              ? AppIcons.check
              : AppIcons.info,
          size: 18,
          color: StatusPill.colorOf(context, tone),
        ),
      ),
      facts: [
        OrderFactRow(
          icon: AppIcons.clock,
          label: order.createdAt == null
              ? 'Sin fecha de creación'
              : 'Creado a las ${formatClock(order.createdAt!)}',
        ),
        if (order.awaitsReturnCheck)
          const OrderFactRow(
            icon: AppIcons.orders,
            label: 'Paquete devuelto por revisar',
          ),
        if (order.requiresColdChain)
          const OrderFactRow(icon: AppIcons.coldChain, label: 'Cadena de frío'),
        if (order.coldChainAlert ||
            order.statusReason != null ||
            order.receiptRejectedReason != null)
          DispatcherOrderAlerts(order: order),
      ],
      dividedFooter: true,
      onTap: onOpen,
      footer: OrderDetailAction(onTap: onOpen),
    );
  }
}
