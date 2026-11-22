import 'package:flutter/material.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../order_row_card.dart';

class InFlightTile extends StatelessWidget {
  const InFlightTile({super.key, required this.order, required this.onWatch});
  final Order order;
  final VoidCallback onWatch;
  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (order.status) {
      OrderStatus.awaitingDelivery => (order.status.label, PillTone.positive),
      OrderStatus.delivered => ('Volviendo a la central', PillTone.neutral),
      _ => (order.status.label, PillTone.attention),
    };
    return OrderRowCard(
      icon: AppIcons.flight,
      tone: Theme.of(context).colorScheme.primary,
      title: order.medicationName,
      accent: '${unitsLabel(order.quantity)} · ${destinationLabel(order)}',
      detail: routeLine(order.assignment),
      onTap: onWatch,
      pill: StatusPill(label: label, tone: tone),
      footer: FilledButton(onPressed: onWatch, child: const Text('Ver vuelo')),
    );
  }
}
