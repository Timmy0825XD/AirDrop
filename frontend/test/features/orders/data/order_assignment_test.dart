import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_models.dart';

Map<String, dynamic> _orderJson({Object? assignment = _absent, String? load}) {
  return {
    'id': 'o1',
    'missionType': 'emergency',
    'destinationKind': 'person',
    'status': 'pending_load',
    'priority': 'high',
    'medicationName': 'Insulina',
    'saleType': 'over_the_counter',
    'requiresColdChain': true,
    'quantity': 1,
    'createdByUserId': 'u1',
    'address': 'Calle 16',
    'hasPrescription': false,
    'loadConfirmedAt': load,
    'createdAt': '2026-10-15T15:00:00.000Z',
    if (assignment != _absent) 'assignment': assignment,
  };
}

const _absent = Object();

const _assignmentJson = {
  'droneId': 'd1',
  'identifier': 'D-01',
  'modelName': 'Wingcopter 198',
  'route': {
    'altitudeM': 100,
    'distanceKm': 4.2,
    'coordinates': [
      [-73.25, 10.46],
      [-73.24, 10.47],
    ],
  },
};

void main() {
  group('Order.fromJson con assignment', () {
    test('lee el dron y el corredor como [longitud, latitud]', () {
      final order = Order.fromJson(_orderJson(assignment: _assignmentJson));
      final a = order.assignment!;
      expect(a.identifier, 'D-01');
      expect(a.modelName, 'Wingcopter 198');
      expect(a.altitudeM, 100);
      expect(a.distanceKm, 4.2);
      expect(a.coordinates.first, [-73.25, 10.46]);
      expect(order.awaitsLoad, isTrue);
    });

    test('assignment null o ausente es "sin asignación"', () {
      expect(Order.fromJson(_orderJson(assignment: null)).assignment, isNull);
      expect(Order.fromJson(_orderJson()).assignment, isNull);
    });

    test('con loadConfirmedAt ya no espera carga', () {
      final order = Order.fromJson(
        _orderJson(load: '2026-10-15T15:05:00.000Z'),
      );
      expect(order.loadConfirmedAt, DateTime.utc(2026, 10, 15, 15, 5));
      expect(order.awaitsLoad, isFalse);
    });
  });

  group('LocalOrderRepository', () {
    test('autorizar reserva dron y pasa a pendiente de carga', () async {
      final repo = LocalOrderRepository();
      final received = (await repo.queue()).first.order;

      final authorized = await repo.authorize(received.id);

      expect(authorized.status, OrderStatus.pendingLoad);
      expect(authorized.assignment?.identifier, 'D-01');
      expect(authorized.loadConfirmedAt, isNull);
      expect(
        (await repo.listPendingLoad()).map((o) => o.id),
        contains(received.id),
      );
    });

    test('confirmar la carga una sola vez', () async {
      final repo = LocalOrderRepository();
      final pending = (await repo.listPendingLoad()).first;

      final confirmed = await repo.confirmLoad(pending.id);
      expect(confirmed.loadConfirmedAt, isNotNull);

      expect(
        () => repo.confirmLoad(pending.id),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
