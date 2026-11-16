import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../data/order_models.dart';

/// El estado del pedido en una pastilla: naranja lo que está en el aire,
/// verde lo que terminó bien, rojo lo que se cortó y marca lo demás.
/// Con [forRequester] dice lo que le importa a quien pidió (sin términos
/// de la central); el despachador y el operador ven el estado técnico.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    super.key,
    required this.status,
    this.forRequester = false,
  });

  final OrderStatus status;
  final bool forRequester;

  static PillTone toneOf(OrderStatus status) => switch (status) {
    OrderStatus.inFlight ||
    OrderStatus.returning ||
    OrderStatus.awaitingConfirmation ||
    OrderStatus.reassigned => PillTone.attention,
    OrderStatus.awaitingDelivery || OrderStatus.delivered => PillTone.positive,
    OrderStatus.rejected ||
    OrderStatus.cancelled ||
    OrderStatus.returned ||
    OrderStatus.skipped ||
    OrderStatus.expired => PillTone.negative,
    _ => PillTone.neutral,
  };

  /// El estado en palabras del solicitante. El regreso del dron no se le
  /// muestra, así que "de regreso" también es "No se entregó".
  static String requesterLabel(OrderStatus status) => switch (status) {
    OrderStatus.received ||
    OrderStatus.underReview => 'Esperando central',
    OrderStatus.assigned || OrderStatus.pendingLoad => 'Preparando el envío',
    OrderStatus.inFlight => 'En camino',
    OrderStatus.delivered => 'Entregado',
    OrderStatus.returning || OrderStatus.returned => 'No se entregó',
    OrderStatus.reassigned => 'Lo atiende otra central',
    _ => status.label,
  };

  /// La etiqueta que se ve, según quién mira.
  static String labelOf(OrderStatus status, {required bool forRequester}) =>
      forRequester ? requesterLabel(status) : status.label;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: labelOf(status, forRequester: forRequester),
      tone: toneOf(status),
    );
  }
}
