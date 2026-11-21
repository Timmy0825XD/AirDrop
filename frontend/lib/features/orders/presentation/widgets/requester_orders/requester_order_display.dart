import '../../../data/order_models.dart';
import '../order_status_chip.dart';

int requesterDeliveryStage(Order order) => switch (order.status) {
  OrderStatus.assigned || OrderStatus.pendingLoad => 1,
  OrderStatus.inFlight => 2,
  OrderStatus.awaitingDelivery => 3,
  OrderStatus.delivered => 4,
  _ => 0,
};

String requesterOrderTitle(OrderStatus status) => switch (status) {
  OrderStatus.underReview => 'En revisión',
  OrderStatus.awaitingDelivery => 'Listo para recibir',
  _ => OrderStatusChip.requesterLabel(status),
};

String requesterOrderDetail(OrderStatus status) => switch (status) {
  OrderStatus.received => 'Tu solicitud espera la revisión de una central.',
  OrderStatus.underReview => 'La central está revisando tu pedido.',
  OrderStatus.assigned ||
  OrderStatus.pendingLoad => 'La central está preparando el envío.',
  OrderStatus.scheduled =>
    'Entrega periódica programada. Consulta su fecha y horario.',
  OrderStatus.awaitingConfirmation =>
    'Confirma que podrás recibir esta entrega.',
  OrderStatus.reassigned => 'Otra central está atendiendo tu solicitud.',
  OrderStatus.delivered => 'Este pedido fue entregado.',
  OrderStatus.returning ||
  OrderStatus.returned => 'El pedido no se entregó. Consulta el detalle.',
  OrderStatus.cancelled => 'Este pedido fue cancelado.',
  OrderStatus.rejected => 'La solicitud no fue autorizada.',
  OrderStatus.skipped => 'Esta entrega periódica se omitió.',
  OrderStatus.expired => 'La franja de esta entrega venció.',
  _ => 'Consulta el detalle de tu pedido.',
};
