import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/presentation/widgets/dispatcher/next_up.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/order_history_screen.dart';

Order _order(
  String id,
  String name, {
  OrderStatus status = OrderStatus.received,
  DateTime? createdAt,
  String? scheduledFor,
  DateTime? scheduledAt,
}) => Order(
  id: id,
  missionType: MissionType.emergency,
  destinationKind: DestinationKind.person,
  status: status,
  priority: OrderPriority.high,
  medicationName: name,
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  address: 'Calle 16',
  hasPrescription: false,
  createdByUserId: 'u1',
  createdAt: createdAt,
  scheduledFor: scheduledFor,
  scheduledAt: scheduledAt,
);

void main() {
  final now = DateTime.utc(2026, 11, 8, 15);

  test('lo que te toca: la urgencia más vieja, la carga y el programado', () {
    final items = dispatcherNextUp(
      queue: [
        QueueEntry(
          order: _order('q2', 'Ibuprofeno', createdAt: now),
          availableQuantity: 4,
          unattended: false,
        ),
        QueueEntry(
          order: _order(
            'q1',
            'Insulina',
            createdAt: now.subtract(const Duration(minutes: 6)),
          ),
          availableQuantity: 2,
          unattended: false,
        ),
      ],
      pendingLoad: [_order('p1', 'Acetaminofén')],
      scheduled: [
        ScheduledEntry(
          order: _order('s2', 'Salbutamol', scheduledFor: '2026-11-10'),
          availableQuantity: 1,
        ),
        ScheduledEntry(
          order: _order('s1', 'Losartán', scheduledFor: '2026-11-09'),
          availableQuantity: 1,
        ),
      ],
      now: now,
    );

    expect(items.map((i) => i.orderId), ['q1', 'p1', 's1']);
    expect(items.first.title, 'Atender la urgencia de Insulina');
    expect(items.first.detail, startsWith('Espera 6 min'));
    expect(items[1].title, 'Cargar Acetaminofén');
  });

  test('sin nada pendiente, la lista va vacía', () {
    expect(
      dispatcherNextUp(
        queue: const [],
        pendingLoad: null,
        scheduled: const [],
        now: now,
      ),
      isEmpty,
    );
  });

  test('"en curso" es lo que no terminó', () {
    expect(isRequesterOrderOpen(_order('a', 'X')), isTrue);
    expect(
      isRequesterOrderOpen(_order('b', 'X', status: OrderStatus.delivered)),
      isFalse,
    );
  });
}
