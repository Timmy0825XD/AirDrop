import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_tab_bar.dart';
import 'package:frontend/core/widgets/requester_tab_bar.dart';
import 'package:frontend/features/home/presentation/widgets/requester/requester_home_orders.dart';
import 'package:frontend/features/home/presentation/widgets/requester/requester_home_plans.dart';
import 'package:frontend/features/home/presentation/widgets/requester/requester_home_values.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/theme/app_palette.dart';

Order _order(String id, OrderStatus status) => Order(
  id: id,
  missionType: MissionType.emergency,
  destinationKind: DestinationKind.person,
  status: status,
  priority: OrderPriority.high,
  medicationName:
      'Solución de rehidratación oral de baja osmolaridad, presentación pediátrica $id',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  address: 'Patio de la casa esquinera',
  hasPrescription: false,
  createdByUserId: 'u1',
);

DeliveryPlan _plan(String id) => DeliveryPlan(
  id: id,
  status: PlanStatus.active,
  frequency: PlanFrequency.weekly,
  medicationName: 'Medicamento periódico $id',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  startDate: '2026-11-21',
  windowEndsOn: '2026-12-21',
  destinationKind: DestinationKind.person,
  address: 'Patio',
  hasPrescription: false,
  renewalDue: false,
);

class _StillTracking extends TrackingNotifier {
  _StillTracking(super.orderId, this.status);
  final OrderStatus status;
  @override
  TrackingState build() =>
      TrackingState(loading: false, connected: true, status: status);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trackingProvider(
          'a',
        ).overrideWith(() => _StillTracking('a', OrderStatus.inFlight)),
        trackingProvider(
          'b',
        ).overrideWith(() => _StillTracking('b', OrderStatus.awaitingDelivery)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
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
  test(
    'los pedidos que ya llegaron van primero y los cerrados no se incluyen',
    () {
      final rows = requesterCurrentOrders([
        _order('a', OrderStatus.inFlight),
        _order('c', OrderStatus.delivered),
        _order('b', OrderStatus.awaitingDelivery),
        _order('d', OrderStatus.returning),
        _order('e', OrderStatus.expired),
      ]);
      expect(rows.map((o) => o.id), ['b', 'a']);
    },
  );

  testWidgets('sin pedidos muestra Todo al día', (tester) async {
    await _pump(
      tester,
      RequesterHomeOrders(orders: const AsyncData([]), onRetry: () {}),
    );
    expect(find.text('Tus pedidos'), findsOneWidget);
    expect(find.text('Todo al día'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'dos pedidos con nombres largos caben a 320 px y texto x$scale',
      (tester) async {
        await _pump(
          tester,
          RequesterHomeOrders(
            orders: AsyncData([
              _order('a', OrderStatus.inFlight),
              _order('b', OrderStatus.awaitingDelivery),
            ]),
            onRetry: () {},
          ),
          scale: scale,
        );
        expect(
          find.textContaining('presentación pediátrica'),
          findsNWidgets(2),
        );
        expect(find.text('Todo al día'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Ver código de entrega'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('muchos pedidos dejan un acceso al resto', (tester) async {
    await _pump(
      tester,
      RequesterHomeOrders(
        orders: AsyncData([
          _order('c', OrderStatus.received),
          _order('d', OrderStatus.assigned),
          _order('e', OrderStatus.pendingLoad),
        ]),
        onRetry: () {},
      ),
    );
    expect(find.text('Ver los 3 pedidos en curso'), findsOneWidget);
    expect(find.textContaining('presentación pediátrica'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('los planes tienen estado vacío y resumen de varios planes', (
    tester,
  ) async {
    await _pump(tester, const RequesterPlansSummary(plans: [], orders: []));
    expect(find.text('Sin entregas periódicas activas'), findsOneWidget);
    await _pump(
      tester,
      RequesterPlansSummary(plans: [_plan('1'), _plan('2')], orders: const []),
      scale: 2,
    );
    expect(find.textContaining('Medicamento periódico'), findsNWidgets(2));
    expect(find.text('Sin entregas periódicas activas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la barra conserva cinco accesos y crece con el texto', (
    tester,
  ) async {
    await _pump(
      tester,
      RequesterTabBar(
        destinations: const [
          NavDestination(icon: Icons.home_rounded, label: 'Inicio'),
          NavDestination(icon: Icons.inventory_2_rounded, label: 'Pedidos'),
          NavDestination(icon: Icons.event_repeat_rounded, label: 'Planes'),
          NavDestination(icon: Icons.person_rounded, label: 'Perfil'),
        ],
        selected: 0,
        onSelect: (_) {},
        center: NavCenterAction(
          icon: Icons.bolt_rounded,
          label: 'Pedir urgencia',
          tabLabel: 'Urgencia',
          onPressed: () {},
        ),
      ),
      scale: 2,
    );
    for (final label in ['Inicio', 'Pedidos', 'Urgencia', 'Planes', 'Perfil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
