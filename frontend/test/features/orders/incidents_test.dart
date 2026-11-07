import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/in_flight/in_flight_tile.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/status_reason_banner.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/theme/app_theme.dart';

const _incident =
    'El dron tuvo un incidente en vuelo; el pedido vuelve a despacharse.';

Order _order(Map<String, dynamic> extra) => Order.fromJson({
  'id': 'o1',
  'missionType': 'emergency',
  'destinationKind': 'person',
  'status': 'received',
  'priority': 'high',
  'medicationName': 'Insulina glargina 100 UI/ml',
  'saleType': 'over_the_counter',
  'requiresColdChain': true,
  'quantity': 1,
  'createdByUserId': 'u1',
  'address': 'Carrera 9 # 15-20',
  ...extra,
});

void main() {
  test('lee lo nuevo de la consola: perdido, incidente, automático', () {
    expect(ReturnOutcome.fromJson('lost'), ReturnOutcome.lost);
    expect(ReturnOutcome.lost.label, 'Paquete perdido');
    expect(QuarantineReason.fromJson('incident'), QuarantineReason.incident);
    expect(FlightAlertKind.fromJson('wind_limit'), FlightAlertKind.windLimit);
    expect(_order({'autoDispatched': true}).autoDispatched, isTrue);
    expect(_order({}).autoDispatched, isFalse);
  });

  test('la telemetría sin enlace se marca como estimada', () {
    Map<String, dynamic> row(Object? linkLost) => {
      'orderId': 'o1',
      'droneId': 'd1',
      'identifier': 'D-01',
      'latitude': 10.46,
      'longitude': -73.25,
      'altitudeM': 100,
      'speedKmh': 80,
      'phase': 'cruise',
      'status': 'in_flight',
      'linkLost': ?linkLost,
    };
    expect(Telemetry.fromJson(row(true)).linkLost, isTrue);
    expect(Telemetry.fromJson(row(null)).linkLost, isFalse);
  });

  test('tras un incidente el motivo es un aviso; en un cierre, no', () {
    final back = _order({'statusReason': _incident});
    expect(back.inProgress, isTrue);
    expect(StatusReasonBanner.reasonOf(back), _incident);

    final closed = _order({
      'status': 'rejected',
      'statusReason': 'Sin fórmula',
    });
    expect(StatusReasonBanner.reasonOf(closed), isNull);

    // Con fallback, `FallbackCard` ya dice el motivo.
    final retry = _order({
      'statusReason': 'Sin dron por ahora.',
      'fallback': {'kind': 'retry'},
    });
    expect(StatusReasonBanner.reasonOf(retry), isNull);
  });

  testWidgets('un entregado cuyo dron vuelve dice "Volviendo a la central"', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: InFlightTile(
            order: _order({'status': 'delivered'}),
            onWatch: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Volviendo a la central'), findsOneWidget);
    expect(find.text('Entregado'), findsNothing);
  });
}
