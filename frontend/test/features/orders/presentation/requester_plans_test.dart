import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_plans/requester_plans_content.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_plans/requester_plans_page.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_plans/requester_plans_values.dart';
import 'package:frontend/theme/app_palette.dart';

final _now = DateTime.utc(2030, 11, 21, 12);

DeliveryPlan _plan(
  String id, {
  bool paused = false,
  PlanStatus status = PlanStatus.active,
  String? name,
}) => DeliveryPlan(
  id: id,
  status: status,
  paused: paused,
  frequency: PlanFrequency.weekly,
  medicationName: name ?? 'Medicamento $id',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  startDate: '2030-11-21',
  windowEndsOn: '2030-12-21',
  destinationKind: DestinationKind.person,
  address: 'Patio de la casa',
  hasPrescription: false,
  renewalDue: false,
);

Order _order(
  String id,
  String planId, {
  OrderStatus status = OrderStatus.scheduled,
  int day = 23,
  bool legacy = false,
}) => Order(
  id: id,
  planId: planId,
  missionType: MissionType.scheduled,
  destinationKind: DestinationKind.person,
  status: status,
  priority: OrderPriority.normal,
  medicationName: 'Medicamento $planId',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  address: 'Patio',
  hasPrescription: false,
  createdByUserId: 'requester',
  scheduledFor: '2030-11-$day',
  scheduledAt: legacy ? null : DateTime.utc(2030, 11, day, 13),
  windowEndsAt: legacy ? null : DateTime.utc(2030, 11, day, 14),
);

Future<GoRouter> _pump(
  WidgetTester tester, {
  List<DeliveryPlan> plans = const [],
  List<Order> orders = const [],
  double scale = 1,
  String? error,
  VoidCallback? onRetry,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => RequesterPlansPage(
          onRefresh: () async {},
          content: RequesterPlansContent(
            plans: plans,
            orders: orders,
            deliveryError: error,
            onRetryDeliveries: onRetry ?? () {},
          ),
        ),
      ),
      GoRoute(
        path: '/orders/plans/new',
        builder: (_, _) => const Scaffold(body: Text('Formulario periódico')),
      ),
      GoRoute(
        path: '/orders/plans/:id',
        builder: (_, state) => Scaffold(
          body: Text('Detalle del plan ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => Scaffold(
          body: Text('Detalle de entrega ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(extensions: const [AppPalette.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _reveal(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'elige la próxima ocurrencia real, excluye pausas y estados cerrados',
    () {
      final result = nextRequesterPlanDelivery(
        [
          _plan('a'),
          _plan('b'),
          _plan('paused', paused: true),
          _plan('cancelled', status: PlanStatus.cancelled),
        ],
        [
          _order('later', 'a', day: 24),
          _order('nearest', 'b', day: 22),
          _order('paused', 'paused', day: 21),
          _order('cancelled', 'cancelled', day: 21),
          _order('expired', 'a', day: 20),
          _order('delivered', 'a', day: 21, status: OrderStatus.delivered),
          _order('other', 'unknown', day: 21),
        ],
        now: _now,
      );
      expect(result?.order.id, 'nearest');
      expect(result?.day.day, 22);
    },
  );

  test('cancelar el plan no oculta una entrega ya despachada', () {
    final result = nextRequesterPlanDelivery(
      [_plan('a', status: PlanStatus.cancelled)],
      [_order('flight', 'a', status: OrderStatus.inFlight, day: 20)],
      now: _now,
    );
    expect(result?.order.id, 'flight');
  });

  test('respeta el día colombiano y los planes antiguos sin hora', () {
    final order = _order('legacy', 'a', day: 21, legacy: true);
    final result = nextRequesterPlanDelivery([_plan('a')], [order], now: _now);
    expect(result?.day.day, 21);
    final timed = RequesterPlanDelivery(_plan('a'), _order('timed', 'a'));
    expect(timed.day.hour, 8);
    expect(nextRequesterPlanDelivery([_plan('a')], [], now: _now), isNull);
  });

  testWidgets('el vacío explica el plan y abre su creación', (tester) async {
    await _pump(tester);
    expect(find.text('Tu próxima entrega empieza aquí'), findsOneWidget);
    expect(find.text('La próxima entrega'), findsNothing);
    await _reveal(tester, 'Crear entrega periódica');
    await tester.tap(find.text('Crear entrega periódica'));
    await tester.pumpAndSettle();
    expect(find.text('Formulario periódico'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmación y Ver plan abren los detalles correspondientes', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      plans: [_plan('a')],
      orders: [
        _order('delivery', 'a', status: OrderStatus.awaitingConfirmation),
      ],
    );
    expect(find.text('8:00 a. m. – 9:00 a. m.'), findsOneWidget);
    expect(find.text('Confirma que podrás recibirla.'), findsOneWidget);
    await _reveal(tester, 'Ver y confirmar');
    await tester.tap(find.text('Ver y confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de entrega delivery'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await _reveal(tester, 'Ver plan');
    await tester.tap(find.text('Ver plan'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del plan a'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('varios planes y nombres largos caben con texto al 200 %', (
    tester,
  ) async {
    await _pump(
      tester,
      scale: 2,
      plans: [
        _plan(
          'a',
          name:
              'Solución de rehidratación oral de baja osmolaridad, presentación pediátrica',
        ),
        _plan('b', paused: true),
        _plan('c', status: PlanStatus.cancelled),
      ],
      orders: [_order('delivery', 'a')],
    );
    expect(find.text('Ver y confirmar'), findsNothing);
    await _reveal(tester, 'Tus planes');
    await _reveal(tester, 'Cancelado');
    expect(find.text('En pausa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el error de pedidos conserva los planes y permite reintentar', (
    tester,
  ) async {
    var retried = false;
    await _pump(
      tester,
      plans: [_plan('a')],
      error: 'No hay conexión.',
      onRetry: () => retried = true,
    );
    expect(find.text('Sin próximas entregas'), findsNothing);
    expect(find.text('Medicamento a'), findsOneWidget);
    await _reveal(tester, 'Reintentar');
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con todos en pausa lo explica sin inventar una próxima fecha', (
    tester,
  ) async {
    await _pump(
      tester,
      plans: [_plan('a', paused: true)],
      orders: [_order('delivery', 'a')],
    );
    expect(find.text('Tus entregas están en pausa'), findsOneWidget);
    expect(find.text('Ver entrega'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
