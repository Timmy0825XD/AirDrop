import '../../../../../core/clock/sim_clock.dart';
import '../../../../orders/data/order_models.dart';

/// Primero lo que ya llegó y requiere el código, después el vuelo y la preparación.
List<Order> requesterCurrentOrders(List<Order> orders) => [
  for (final status in [
    OrderStatus.awaitingDelivery,
    OrderStatus.inFlight,
    OrderStatus.pendingLoad,
    OrderStatus.assigned,
    OrderStatus.underReview,
    OrderStatus.received,
    OrderStatus.reassigned,
  ])
    ...orders.where((o) => o.status == status),
];

Order? requesterNextDelivery(List<Order> orders) {
  final now = simClock.now();
  final upcoming = orders
      .where(
        (o) =>
            o.scheduledAt != null &&
            o.scheduledAt!.isAfter(now) &&
            (o.status == OrderStatus.scheduled ||
                o.status == OrderStatus.awaitingConfirmation),
      )
      .toList();
  upcoming.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
  return upcoming.firstOrNull;
}
