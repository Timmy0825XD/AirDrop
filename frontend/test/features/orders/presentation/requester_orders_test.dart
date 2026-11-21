import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/order_history_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_orders/requester_order_card.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_orders/requester_order_display.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_orders/requester_orders_page.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/theme/app_palette.dart';

Order _order(
  String id,
  OrderStatus status, {
  String name = 'Medicamento solicitado',
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
  address: 'Patio',
  hasPrescription: false,
  createdByUserId: 'requester',
);

class _Flight extends TrackingNotifier {
  _Flight() : super('flight');
  @override
  TrackingState build() => const TrackingState(
    loading: false,
    connected: true,
    status: OrderStatus.inFlight,
    telemetry: Telemetry(
      orderId: 'flight',
      droneId: 'drone',
      identifier: 'D-01',
      latitude: 10.46,
      longitude: -73.25,
      altitudeM: 100,
      speedKmh: 90,
      phase: FlightPhase.cruise,
      status: OrderStatus.inFlight,
      etaSeconds: 360,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool page = false,
  double scale = 1,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [trackingProvider('flight').overrideWith(_Flight.new)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: page
              ? child
              : Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('el historial incluye estados terminales y los excluye de En curso', () {
    for (final status in [
      OrderStatus.delivered,
      OrderStatus.returned,
      OrderStatus.rejected,
      OrderStatus.cancelled,
      OrderStatus.skipped,
      OrderStatus.expired,
    ]) {
      expect(isRequesterOrderOpen(_order('closed', status)), isFalse);
    }
    expect(
      isRequesterOrderOpen(_order('open', OrderStatus.awaitingConfirmation)),
      isTrue,
    );
  });

  test(
    'el seguimiento no confunde la llegada con la confirmación del código',
    () {
      expect(requesterDeliveryStage(_order('a', OrderStatus.inFlight)), 2);
      expect(
        requesterDeliveryStage(_order('a', OrderStatus.awaitingDelivery)),
        3,
      );
      expect(requesterDeliveryStage(_order('a', OrderStatus.delivered)), 4);
    },
  );

  testWidgets('en vuelo muestra pasos, ETA real, vuelo y código', (
    tester,
  ) async {
    await _pump(
      tester,
      RequesterOrderCard(
        order: _order('flight', OrderStatus.inFlight),
        active: true,
      ),
    );
    expect(find.text('Solicitud recibida'), findsOneWidget);
    expect(find.text('Recibir con código'), findsOneWidget);
    expect(find.text('Llega en 6 min'), findsOneWidget);
    expect(find.text('Ver vuelo'), findsOneWidget);
    expect(find.text('Ver código'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('una solicitud sin cargar no ofrece vuelo ni código', (
    tester,
  ) async {
    await _pump(
      tester,
      RequesterOrderCard(
        order: _order('pending', OrderStatus.pendingLoad),
        active: true,
      ),
    );
    expect(find.text('Ver vuelo'), findsNothing);
    expect(find.text('Ver código'), findsNothing);
    expect(find.text('La central está preparando el envío.'), findsOneWidget);
  });

  testWidgets('el historial de una entrega no vuelve a ofrecer el código', (
    tester,
  ) async {
    await _pump(
      tester,
      RequesterOrderCard(
        order: _order('delivered', OrderStatus.delivered),
        active: false,
      ),
    );
    expect(find.text('Este pedido fue entregado.'), findsOneWidget);
    expect(find.text('Ver código'), findsNothing);
    expect(find.text('Recibir con código'), findsNothing);
  });

  testWidgets('nombre largo y texto al 200 % no desbordan la tarjeta', (
    tester,
  ) async {
    await _pump(
      tester,
      RequesterOrderCard(
        order: _order(
          'flight',
          OrderStatus.inFlight,
          name:
              'Solución de rehidratación oral de baja osmolaridad, presentación pediátrica',
        ),
        active: true,
      ),
      scale: 2,
    );
    await tester.ensureVisible(find.text('Ver código'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'busca por medicamento y deja limpiar una búsqueda sin resultados',
    (tester) async {
      await _pump(
        tester,
        RequesterOrdersPage(
          onlyOpen: true,
          rows: AsyncData([
            _order('a', OrderStatus.received, name: 'Vacuna de prueba'),
            _order('b', OrderStatus.underReview, name: 'Solución de prueba'),
          ]),
          onRefresh: () {},
          onFilter: (_) {},
        ),
        page: true,
      );
      await tester.tap(find.byTooltip('Buscar pedido'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'vacuna');
      await tester.pumpAndSettle();
      expect(find.text('Vacuna de prueba'), findsOneWidget);
      expect(find.text('Solución de prueba'), findsNothing);
      await tester.enterText(find.byType(TextField), 'No existe en la lista');
      await tester.pumpAndSettle();
      expect(find.text('Limpiar búsqueda'), findsOneWidget);
      await tester.tap(find.text('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Vacuna de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('la pantalla vacía soporta texto grande y teclado visible', (
    tester,
  ) async {
    await _pump(
      tester,
      RequesterOrdersPage(
        onlyOpen: false,
        rows: const AsyncData([]),
        onRefresh: () {},
        onFilter: (_) {},
      ),
      page: true,
      scale: 2,
      keyboard: 300,
    );
    expect(find.text('Historial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
