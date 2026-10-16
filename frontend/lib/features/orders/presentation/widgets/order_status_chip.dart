import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../data/order_models.dart';

/// El estado del pedido en una pastilla: naranja lo que está en el aire,
/// verde lo que terminó bien, rojo lo que se cortó y marca lo demás.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  static PillTone toneOf(OrderStatus status) => switch (status) {
    OrderStatus.inFlight || OrderStatus.returning => PillTone.attention,
    OrderStatus.awaitingDelivery || OrderStatus.delivered => PillTone.positive,
    OrderStatus.rejected ||
    OrderStatus.cancelled ||
    OrderStatus.returned => PillTone.negative,
    _ => PillTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: status.label, tone: toneOf(status));
  }
}
