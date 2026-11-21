import '../../../../../core/clock/sim_clock.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

class RequesterPlanDelivery {
  const RequesterPlanDelivery(this.plan, this.order);
  final DeliveryPlan plan;
  final Order order;

  DateTime get day => _orderDay(order)!;
}

DateTime? _orderDay(Order order) {
  final date = order.scheduledAt != null
      ? colombiaTime(order.scheduledAt!)
      : DateTime.tryParse(order.scheduledFor ?? '');
  if (date == null) return null;
  return DateTime(date.year, date.month, date.day, date.hour, date.minute);
}

const _scheduled = {OrderStatus.scheduled, OrderStatus.awaitingConfirmation};
const _preparing = {
  OrderStatus.received,
  OrderStatus.underReview,
  OrderStatus.reassigned,
};
const _dispatched = {
  OrderStatus.assigned,
  OrderStatus.pendingLoad,
  OrderStatus.inFlight,
  OrderStatus.awaitingDelivery,
};

/// Solo ocurrencias reales de estos planes; nunca calcula nuevas fechas.
RequesterPlanDelivery? nextRequesterPlanDelivery(
  List<DeliveryPlan> plans,
  List<Order> orders, {
  DateTime? now,
}) {
  final current = now ?? simClock.now();
  final today = colombiaToday(current);
  final byId = {for (final plan in plans) plan.id: plan};
  final candidates = <RequesterPlanDelivery>[];
  for (final order in orders) {
    final plan = byId[order.planId];
    if (plan == null) continue;
    final dispatched = _dispatched.contains(order.status);
    if (!dispatched) {
      if (plan.status != PlanStatus.active || plan.paused) continue;
      if (!_scheduled.contains(order.status) &&
          !_preparing.contains(order.status)) {
        continue;
      }
      if (order.windowEndsAt != null && !order.windowEndsAt!.isAfter(current)) {
        continue;
      }
    }
    final day = _orderDay(order);
    if (day == null) continue;
    if (!dispatched && DateTime(day.year, day.month, day.day).isBefore(today)) {
      continue;
    }
    candidates.add(RequesterPlanDelivery(plan, order));
  }
  candidates.sort((a, b) => a.day.compareTo(b.day));
  return candidates.firstOrNull;
}

String requesterPlanState(DeliveryPlan plan) =>
    plan.status == PlanStatus.active && plan.paused
    ? 'En pausa'
    : plan.status.label;
