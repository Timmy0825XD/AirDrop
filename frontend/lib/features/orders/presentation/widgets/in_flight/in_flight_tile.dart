import 'package:flutter/material.dart';
import '../../../../../core/widgets/drone_glyph.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../dispatcher_flight_route.dart';
import '../dispatcher_order_alerts.dart';
import '../dispatcher_order_card.dart';
import '../order_fact_row.dart';

class InFlightTile extends StatelessWidget {
  const InFlightTile({super.key, required this.order, required this.onWatch});
  final Order order;
  final VoidCallback onWatch;
  @override
  Widget build(BuildContext context) {
    final returning =
        order.status == OrderStatus.returning ||
        order.status == OrderStatus.delivered;
    final (label, tone) = switch (order.status) {
      OrderStatus.inFlight => ('En camino', PillTone.neutral),
      OrderStatus.awaitingDelivery => ('Espera la entrega', PillTone.attention),
      OrderStatus.returning ||
      OrderStatus.delivered => ('De regreso', PillTone.neutral),
      _ => (order.status.label, PillTone.neutral),
    };
    final color = returning
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : StatusPill.colorOf(context, tone);
    return DispatcherOrderCard(
      title: order.medicationName,
      subtitle: returning
          ? 'Retorno a tu central'
          : '${unitsLabel(order.quantity)} · ${destinationLabel(order)}',
      onTap: onWatch,
      status: StatusPill(
        label: label,
        tone: tone,
        subdued: returning,
        wrapLabel: true,
        leading: returning
            ? Icon(AppIcons.undo, size: 18, color: color)
            : DroneGlyph(size: 18, color: color),
      ),
      facts: [
        DispatcherFlightRoute(returning: returning),
        if (order.assignment case final drone?)
          OrderFactRow(
            icon: AppIcons.drone,
            label: '${drone.modelName} ${drone.identifier}',
          ),
        if (returning) Text(unitsLabel(order.quantity)),
        if (order.requiresColdChain)
          const OrderFactRow(
            icon: AppIcons.coldChain,
            label: 'Cadena de frío · 2 a 8 °C',
          ),
        if (order.coldChainAlert ||
            order.statusReason != null ||
            order.receiptRejectedReason != null)
          DispatcherOrderAlerts(order: order),
      ],
      footer: returning
          ? OutlinedButton(onPressed: onWatch, child: const Text('Ver vuelo'))
          : FilledButton(onPressed: onWatch, child: const Text('Ver vuelo')),
    );
  }
}
