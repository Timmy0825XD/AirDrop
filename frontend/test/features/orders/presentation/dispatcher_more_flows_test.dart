import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/core/widgets/auth_field.dart';
import 'package:frontend/core/widgets/content_page.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/agenda_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/dispatch_history_screen.dart';
import 'package:frontend/features/orders/presentation/hub_emergency_screen.dart';
import 'package:frontend/features/orders/presentation/incoming_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/pending_load/pending_load_tile.dart';
import 'package:frontend/features/orders/presentation/widgets/in_flight/in_flight_tile.dart';
import 'package:frontend/features/orders/presentation/widgets/tray_content.dart';
import 'package:frontend/theme/app_icons.dart';
import 'package:frontend/theme/app_palette.dart';

Order _order(String id, {OrderStatus status = OrderStatus.pendingLoad}) =>
    Order(
      id: id,
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.hub,
      status: status,
      priority: OrderPriority.high,
      medicationName: 'Solución de rehidratación oral de baja osmolaridad $id',
      saleType: SaleType.prescription,
      requiresColdChain: true,
      quantity: 2,
      address: 'Central La Paz',
      hasPrescription: false,
      createdByUserId: 'u',
      createdAt: DateTime.utc(2026, 11, 21, 15),
      originHubId: 'origin',
      destinationHubId: 'mine',
      droneId: 'd',
      assignment: const OrderAssignment(
        droneId: 'd',
        identifier: 'G-04',
        modelName: 'Garza',
        altitudeM: 100,
        distanceKm: 4.2,
        coordinates: [],
      ),
    );

Future<void> _mount(
  WidgetTester tester,
  Widget widget, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.light]),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 720),
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: widget,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _bring(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Widget _tray({
  List<Order>? items,
  String? error,
  bool loading = false,
  VoidCallback? retry,
}) => ContentPage(
  title: 'Pedidos',
  subtitle: 'Tu central',
  slivers: [
    TrayContent<Order>(
      items: items,
      loading: loading,
      error: error,
      emptyIcon: AppIcons.orders,
      emptyTitle: 'Todo al día',
      emptyText: 'No hay pedidos pendientes.',
      onRefresh: retry ?? () {},
      keyOf: (order) => order.id,
      itemBuilder: (_, order) => Text(order.medicationName),
    ),
  ],
);

class _CreateEmergency extends CreateHubEmergencyNotifier {
  CreateHubEmergencyRequest? request;
  @override
  Future<Order?> build() async => null;
  @override
  Future<Order> create(CreateHubEmergencyRequest value) async {
    request = value;
    return _order('created', status: OrderStatus.received);
  }
}

const _offer = CatalogOffer(
  name: 'Suero oral',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  availableQuantity: 30,
);
const _origin = OriginHub(
  id: 'origin',
  name: 'Central La Paz',
  address: 'La Paz',
);
const _hub = Hub(
  id: 'mine',
  name: 'Hospital Central',
  type: HubType.hospital,
  address: 'Valledupar',
  latitude: 10.4,
  longitude: -73.2,
  contactPhone: '3001234567',
  status: HubStatus.active,
);

void main() {
  setUp(
    () => simClock.apply(
      ClockView(now: DateTime.utc(2026, 11, 21, 15), speed: 1, paused: true),
    ),
  );
  tearDown(simClock.reset);
  testWidgets(
    'las bandejas distinguen vacío y error y conservan datos al fallar una recarga',
    (tester) async {
      var refreshed = 0;
      await _mount(tester, _tray(items: [], retry: () => refreshed++));
      await _bring(tester, find.text('Actualizar'));
      await tester.tap(find.text('Actualizar'));
      expect(refreshed, 1);
      await _mount(
        tester,
        _tray(error: 'Sin conexión', retry: () => refreshed++),
      );
      expect(find.text('Todo al día'), findsNothing);
      await _bring(tester, find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      expect(refreshed, 2);
      await _mount(
        tester,
        _tray(items: [_order('known')], error: 'Sin conexión'),
      );
      await _bring(tester, find.text(_order('known').medicationName));
      expect(find.text(_order('known').medicationName), findsOneWidget);
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'entrantes ofrece recibir y vuelve a Más sin ofrecer vuelo al receptor',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/more',
        routes: [
          GoRoute(
            path: '/more',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/incoming'),
                child: const Text('Abrir entrantes'),
              ),
            ),
          ),
          GoRoute(path: '/incoming', builder: (_, _) => const IncomingScreen()),
          GoRoute(
            path: '/delivery/:id',
            builder: (_, _) => const Scaffold(body: Text('Código de entrega')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            incomingProvider.overrideWith(
              (ref) async => [
                _order('incoming', status: OrderStatus.awaitingDelivery),
              ],
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(extensions: const [AppPalette.light]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir entrantes'));
      await tester.pumpAndSettle();
      expect(find.text('Ver vuelo'), findsNothing);
      await _bring(tester, find.text('Recibir pedido'));
      await tester.tap(find.text('Recibir pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Código de entrega'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir entrantes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tarjetas con nombres largos y frío caben a 320 px con texto x2',
    (tester) async {
      var reviewed = 0;
      await _mount(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                PendingLoadTile(
                  order: _order('load'),
                  confirming: false,
                  onConfirm: () => reviewed++,
                  onOpen: () {},
                ),
                const SizedBox(height: 12),
                InFlightTile(
                  order: _order('flight', status: OrderStatus.delivered),
                  onWatch: () {},
                ),
              ],
            ),
          ),
        ),
        scale: 2,
      );
      await _bring(tester, find.text('Revisar y cargar'));
      await tester.tap(find.text('Revisar y cargar'));
      expect(reviewed, 1);
      await _bring(tester, find.text('Volviendo a la central'));
      expect(find.text('Volviendo a la central'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'historial conserva la primera página si falla la segunda y permite reintentar y filtrar',
    (tester) async {
      var secondAttempts = 0;
      await _mount(
        tester,
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            historyProvider.overrideWith((ref, query) async {
              if (query.status != null) {
                return const HistoryPage(
                  items: [],
                  total: 0,
                  page: 1,
                  pageSize: 1,
                );
              }
              if (query.page == 2 && secondAttempts++ == 0) {
                throw const ApiException('Falló la segunda página.');
              }
              return HistoryPage(
                items: [
                  _order('page${query.page}', status: OrderStatus.delivered),
                ],
                total: 2,
                page: query.page,
                pageSize: 1,
              );
            }),
          ],
          child: const DispatchHistoryScreen(),
        ),
      );
      await _bring(tester, find.text('Cargar más'));
      await tester.tap(find.text('Cargar más'));
      await tester.pumpAndSettle();
      expect(find.text(_order('page1').medicationName), findsOneWidget);
      await _bring(tester, find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await _bring(tester, find.text(_order('page2').medicationName));
      expect(secondAttempts, 2);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devueltos'));
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Sin pedidos con este filtro'));
      expect(find.text('Sin pedidos con este filtro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'urgencia entre centrales elige insumo y origen, valida stock y envía el mismo contrato',
    (tester) async {
      final create = _CreateEmergency();
      final router = GoRouter(
        initialLocation: '/request',
        routes: [
          GoRoute(
            path: '/request',
            builder: (_, _) => const HubEmergencyScreen(),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (_, _) => const Scaffold(body: Text('Solicitud creada')),
          ),
          GoRoute(path: '/more', builder: (_, _) => const Scaffold()),
        ],
      );
      addTearDown(router.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            catalogProvider.overrideWith((ref) async => [_offer]),
            offerSourcesProvider.overrideWith(
              (ref, offer) async => [(hub: _origin, offer: _offer)],
            ),
            originHubsProvider.overrideWith((ref) async => [_origin]),
            myHubProvider.overrideWith((ref) async => _hub),
            createHubEmergencyProvider.overrideWith(() => create),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(extensions: const [AppPalette.light]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elige el medicamento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suero oral'));
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Elige de qué central sale'));
      await tester.tap(find.text('Elige de qué central sale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Central La Paz'));
      await tester.pumpAndSettle();
      final input = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is AuthField && w.label == 'Cantidad',
        ),
        matching: find.byType(TextField),
      );
      await _bring(tester, input);
      await tester.enterText(input, '31');
      await _bring(tester, find.text('Enviar solicitud'));
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(create.request, isNull);
      expect(
        find.text('La cantidad debe ser un entero entre 1 y 30.'),
        findsOneWidget,
      );
      await _bring(tester, input);
      await tester.enterText(input, '10');
      await _bring(tester, find.text('Enviar solicitud'));
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(create.request?.toJson(), {
        'originHubId': 'origin',
        'medicationName': 'Suero oral',
        'saleType': 'over_the_counter',
        'quantity': 10,
      });
      expect(find.text('Solicitud creada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
