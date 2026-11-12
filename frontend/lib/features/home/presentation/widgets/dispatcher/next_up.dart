import 'package:flutter/material.dart';

import '../../../../../core/widgets/status_pill.dart';
import '../../../../orders/data/order_models.dart';
import '../../../../orders/presentation/order_format.dart';
import '../../../../orders/presentation/widgets/queue_wait.dart';

/// Lo primero que tiene que hacer el despachador, en este orden: la
/// urgencia que más lleva esperando, el dron que espera la carga y el
/// próximo programado. Solo lo que existe; sin nada, la lista va vacía.
List<NextUpItem> dispatcherNextUp({
  required List<QueueEntry>? queue,
  required List<Order>? pendingLoad,
  required List<ScheduledEntry>? scheduled,
  required DateTime now,
}) => [
  if (_oldest(queue) case final entry?) _urgencyItem(entry, now),
  if (_oldestOrder(pendingLoad) case final order?) _loadItem(order),
  if (_soonest(scheduled) case final order?) _scheduledItem(order),
];

NextUpItem _urgencyItem(QueueEntry entry, DateTime now) {
  final wait = queueWaitMinutes(entry.order.createdAt, now);
  return NextUpItem(
    title: 'Atender la urgencia de ${entry.order.medicationName}',
    detail: '${queueWaitLabel(wait)} · ${destinationLabel(entry.order)}',
    icon: Icons.emergency_outlined,
    tone: queueWaitTone(wait, unattended: entry.unattended),
    orderId: entry.order.id,
  );
}

NextUpItem _loadItem(Order order) {
  final drone = order.assignment?.identifier;
  return NextUpItem(
    title: 'Cargar ${order.medicationName}',
    detail: drone == null
        ? 'El dron espera el insumo'
        : 'El dron $drone espera el insumo',
    icon: Icons.inventory_2_outlined,
    tone: PillTone.attention,
    orderId: order.id,
  );
}

NextUpItem _scheduledItem(Order order) {
  final at = order.scheduledAt;
  final day = order.scheduledFor;
  return NextUpItem(
    title: 'Próximo programado: ${order.medicationName}',
    detail: at != null
        ? capitalized(formatDateTime(at))
        : day != null
        ? capitalized(formatDay(day))
        : 'Sin fecha',
    icon: Icons.event_note_outlined,
    tone: PillTone.neutral,
    orderId: order.id,
  );
}

/// La urgencia que más lleva en la cola.
QueueEntry? _oldest(List<QueueEntry>? rows) {
  if (rows == null || rows.isEmpty) return null;
  return ([...rows]..sort((a, b) => _byCreated(a.order, b.order))).first;
}

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
    required this.detail,
    required this.icon,
    required this.tone,
    required this.orderId,
  });

  final String title;
  final String detail;
  final IconData icon;
  final PillTone tone;
  final String orderId;
}
