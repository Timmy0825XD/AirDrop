import '../../../data/order_models.dart';
import '../../order_format.dart';

/// RU-30: quien recibe una entrega de plan la confirma, la omite o la
/// mueve, siempre que no tenga dron y falten 2 horas o más. Es una pista
/// del reloj del teléfono: la verdad es la respuesta de Nest.
class OccurrenceRules {
  const OccurrenceRules(this.order, this.now);

  final Order order;
  final DateTime now;

  static const _margin = Duration(hours: 2);

  /// Es una entrega de plan en un estado que quien recibe todavía mira.
  bool get applies =>
      order.planId != null &&
      (order.status == OrderStatus.scheduled ||
          order.status == OrderStatus.awaitingConfirmation ||
          (order.status == OrderStatus.received && order.droneId == null));

  /// Sin dron y a 2 horas o más de la franja.
  bool get changeable {
    if (!applies || order.droneId != null) return false;
    final start = order.scheduledAt;
    return start == null || start.difference(now) >= _margin;
  }

  /// Todavía falta confirmarla (T-24 h) o aún no se le pidió.
  bool get canConfirm =>
      changeable &&
      (order.status == OrderStatus.awaitingConfirmation ||
          order.status == OrderStatus.scheduled);

  bool get awaitsConfirmation =>
      order.status == OrderStatus.awaitingConfirmation;

  /// "jueves 5 de noviembre, 10:00 – 11:00".
  String get slotLabel {
    final date = order.scheduledFor;
    final slot = formatSlot(order.scheduledAt, order.windowEndsAt);
    return date == null ? slot : '${formatLongDate(date)}, $slot';
  }

  /// Se mueve al mismo día o al siguiente de la fecha original.
  List<String> get rescheduleDates {
    final base = DateTime.tryParse(order.scheduledFor ?? '');
    if (base == null) return const [];
    return [isoDate(base), isoDate(base.add(const Duration(days: 1)))];
  }
}
