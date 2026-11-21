import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/features/tracking/presentation/widgets/flight_notice.dart';

final _arrival = TrackingState(
  loading: false,
  connected: true,
  status: OrderStatus.awaitingDelivery,
  telemetry: Telemetry.fromJson({
    'orderId': 'o1',
    'droneId': 'd1',
    'identifier': 'AD-NEV-01',
    'latitude': 10.46,
    'longitude': -73.25,
    'altitudeM': 0,
    'speedKmh': 0,
    'phase': 'landed',
    'status': 'awaiting_delivery',
  }),
);

Widget _notice(TrackingState state, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: FlightNotice(state: state)),
  ),
);

Future<void> _checkFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 30; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  }
}

void main() {
  testWidgets('la llegada muestra el aviso sin errores durante la animación', (
    tester,
  ) async {
    await tester.pumpWidget(_notice(const TrackingState(loading: false)));
    await tester.pumpWidget(_notice(_arrival));
    await _checkFrames(tester);
    expect(
      find.text('El dron llegó. Hay 5 minutos para recibirlo con el código.'),
      findsOneWidget,
    );
  });

  testWidgets('un retorno durante el aviso de llegada no rompe la transición', (
    tester,
  ) async {
    await tester.pumpWidget(_notice(const TrackingState(loading: false)));
    await tester.pumpWidget(_notice(_arrival));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(
      _notice(const TrackingState(loading: false, status: OrderStatus.returning)),
    );
    await _checkFrames(tester);
    expect(find.textContaining('El pedido no se entregó.'), findsOneWidget);
  });

  testWidgets('con movimiento reducido la llegada se muestra sin transición', (
    tester,
  ) async {
    await tester.pumpWidget(
      _notice(const TrackingState(loading: false), reduced: true),
    );
    await tester.pumpWidget(_notice(_arrival, reduced: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('El dron llegó.'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
