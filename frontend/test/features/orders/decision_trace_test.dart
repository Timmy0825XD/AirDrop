import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/decision/decision_section.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/decision/decision_summary.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/decision/offer_ladder.dart';
import 'package:frontend/theme/app_theme.dart';

/// El ejemplo de §14 de `pendientes-backend.md`, tal cual lo manda Nest.
final _json = <String, dynamic>{
  'orderId': 'o1',
  'trace': {
    'at': '2026-11-02T15:01:00.000Z',
    'outcome': 'assigned',
    'reason': null,
    'hubs': [
      {
        'hubId': 'h1',
        'name': 'Hospital Rosario',
        'lot': true,
        'corridorKm': 11,
        'etaMin': 5.4,
        'batteryNeededPercent': 56,
        'inRange': true,
        'note': null,
        'drones': [
          {
            'identifier': 'WC-01',
            'status': 'discarded',
            'reason': 'El dron está en mantenimiento.',
            'preempts': false,
            'batteryPercent': 100,
          },
          {
            'identifier': 'WC-02',
            'status': 'chosen',
            'reason': null,
            'preempts': false,
            'batteryPercent': 88,
          },
        ],
      },
    ],
  },
  'offers': [
    {
      'hubId': 'h2',
      'name': 'Clínica del Cesar',
      'etaMin': 4,
      'ready': true,
      'offeredAt': '2026-11-02T15:00:00.000Z',
      'declinedAt': '2026-11-02T15:00:40.000Z',
      'declineReason': 'Sin dron disponible',
    },
    {
      'hubId': 'h1',
      'name': 'Hospital Rosario',
      'etaMin': 6,
      'ready': true,
      'offeredAt': '2026-11-02T15:00:40.000Z',
      'declinedAt': null,
      'declineReason': null,
    },
  ],
};

void main() {
  test('lee la traza y resume qué dron salió', () {
    final decision = OrderDecision.fromJson(_json);
    final chosen = decision.trace!.chosen!;
    expect(chosen.drone.identifier, 'WC-02');
    expect(decisionSummary(decision), 'Se asignó WC-02 de Hospital Rosario.');
    expect(hubTraceFacts(decision.trace!.hubs.single), contains('5,4 min'));
  });

  test('sin traza lo dice, y la escalera dice quién declinó', () {
    expect(
      decisionSummary(const OrderDecision()),
      startsWith('El motor todavía no decidió este pedido'),
    );
    final offers = OrderDecision.fromJson(_json).offers!;
    expect(
      offerState(offers.first),
      'declinó a las 10:00 a. m.: Sin dron disponible',
    );
    expect(offerState(offers.last), 'desde las 10:00 a. m.');
  });

  testWidgets('la sección empieza cerrada y abre cada central y dron', (
    tester,
  ) async {
    // Un teléfono de 360 px: un desborde haría fallar la prueba.
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DecisionSection(decision: OrderDecision.fromJson(_json)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Se asignó WC-02 de Hospital Rosario.'), findsOneWidget);
    expect(find.text('Descartado'), findsNothing);

    await tester.tap(find.text('Ver cada central y dron'));
    await tester.pumpAndSettle();
    expect(find.text('Elegido'), findsOneWidget);
    expect(find.text('Descartado'), findsOneWidget);
    expect(
      find.textContaining('El dron está en mantenimiento.'),
      findsOneWidget,
    );
    expect(find.textContaining('Clínica del Cesar'), findsOneWidget);
  });
}
