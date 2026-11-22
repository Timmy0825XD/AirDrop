import 'package:flutter/material.dart';

import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../orders/data/order_models.dart';
import '../../../../orders/presentation/order_format.dart';
import '../../../../orders/presentation/widgets/queue_wait.dart';

/// Lo primero que tiene que hacer el despachador, en este orden: la
/// primera urgencia según Nest, la carga, el traslado que ya llegó y el
/// próximo programado. No se reordena la prioridad de la cola en el cliente.
List<NextUpItem> dispatcherNextUp({
  required List<QueueEntry>? queue,
  required List<Order>? pendingLoad,
  required List<ScheduledEntry>? scheduled,
  required DateTime now,
  List<Order>? incoming,
}) => [
  if (queue?.firstOrNull case final entry?) _urgencyItem(entry, now),
  if (_oldestOrder(pendingLoad) case final order?) _loadItem(order),
  if (incoming
          ?.where((o) => o.status == OrderStatus.awaitingDelivery)
          .firstOrNull
      case final order?)
    _incomingItem(order),
  if (_soonest(scheduled) case final order?) _scheduledItem(order),
];

NextUpItem _urgencyItem(QueueEntry entry, DateTime now) {
  final wait = queueWaitMinutes(entry.order.createdAt, now);
  return NextUpItem(
    label: entry.order.triage?.hasRedFlag == true
        ? 'Signo de alarma · ${queueWaitLabel(wait)}'
        : 'Urgencia · ${queueWaitLabel(wait)}',
    title: entry.order.medicationName,
    detail:
        '${unitsLabel(entry.order.quantity)} · ${destinationLabel(entry.order)}',
    actionLabel: 'Revisar solicitud',
    icon: AppIcons.urgency,
    tone: entry.order.triage?.hasRedFlag == true
        ? PillTone.negative
        : queueWaitTone(wait, unattended: entry.unattended),
    orderId: entry.order.id,
  );
}

NextUpItem _loadItem(Order order) {
  final drone = order.assignment?.identifier;
  return NextUpItem(
    label: 'Pendiente de carga',
    title: order.medicationName,
    detail: drone == null
        ? 'El dron espera el insumo'
        : 'El dron $drone espera el insumo',
    actionLabel: 'Preparar carga',
    icon: AppIcons.orders,
    tone: PillTone.attention,
    orderId: order.id,
  );
}

NextUpItem _scheduledItem(Order order) {
  final at = order.scheduledAt;
  final day = order.scheduledFor;
  return NextUpItem(
    label: 'Próximo programado',
    title: order.medicationName,
    detail: at != null
        ? capitalized(formatDateTime(at))
        : day != null
        ? capitalized(formatDay(day))
        : 'Sin fecha',
    actionLabel: 'Revisar entrega',
    icon: AppIcons.calendar,
    tone: PillTone.neutral,
    orderId: order.id,
  );
}

NextUpItem _incomingItem(Order order) => NextUpItem(
  label: 'Traslado en tu central',
  title: order.medicationName,
  detail: '${unitsLabel(order.quantity)} · Esperando el código de entrega',
  actionLabel: 'Recibir traslado',
  icon: AppIcons.incoming,
  tone: PillTone.attention,
  orderId: order.id,
  destination: '/delivery/${order.id}',
);

/// El pedido por cargar más viejo.
Order? _oldestOrder(List<Order>? rows) {
  if (rows == null || rows.isEmpty) return null;
  return ([...rows]..sort(_byCreated)).first;
}

/// El programado que sale antes (por hora; si no tiene, por día).
Order? _soonest(List<ScheduledEntry>? rows) {
  if (rows == null || rows.isEmpty) return null;
  final orders = rows.map((e) => e.order).toList()
    ..sort((a, b) => _whenOf(a).compareTo(_whenOf(b)));
  return orders.first;
}

String _whenOf(Order o) =>
    o.scheduledAt?.toUtc().toIso8601String() ?? o.scheduledFor ?? '9999';

int _byCreated(Order a, Order b) {
  final x = a.createdAt;
  final y = b.createdAt;
  if (x == null && y == null) return 0;
  if (x == null || y == null) return x == null ? 1 : -1;
  return x.compareTo(y);
}

/// Una tarea de "Para atender ahora": qué es, el detalle, su tono y el
/// pedido que abre.
@immutable
class NextUpItem {
  const NextUpItem({
    required this.title,
    required this.label,
    required this.detail,
    required this.actionLabel,
    required this.icon,
    required this.tone,
    required this.orderId,
    this.destination,
  });

  final String title;
  final String label;
  final String detail;
  final String actionLabel;
  final IconData icon;
  final PillTone tone;
  final String orderId;
  final String? destination;
  String get path => destination ?? '/orders/$orderId';
}
