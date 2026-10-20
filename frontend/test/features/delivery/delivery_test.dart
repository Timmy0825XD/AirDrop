import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/features/delivery/data/delivery_models.dart';
import 'package:frontend/features/delivery/data/delivery_providers.dart';
import 'package:frontend/features/delivery/data/delivery_repository.dart';
import 'package:frontend/features/delivery/presentation/receive_order_screen.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/dispatcher_permissions.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/features/tracking/presentation/widgets/flight_notice.dart';
import 'package:go_router/go_router.dart';

Order _order({
  OrderStatus status = OrderStatus.awaitingDelivery,
  DestinationKind destination = DestinationKind.hub,
  String? destinationHubId = 'h2',
}) {
  return Order(
    id: 'o1',
    missionType: MissionType.emergency,
    destinationKind: destination,
    status: status,
    priority: OrderPriority.high,
    medicationName: 'Insulina',
    saleType: SaleType.overTheCounter,
    requiresColdChain: false,
    quantity: 1,
    address: 'Calle 16',
    hasPrescription: false,
    createdByUserId: 'u1',
    originHubId: 'h1',
    destinationHubId: destinationHubId,
  );
}

/// Nest de mentira: el código es `135790` y vence cuando diga el test.
class _FakeDelivery implements DeliveryRepository {
  _FakeDelivery({required this.expiresAt, this.generateError});

  final DateTime expiresAt;
  final String? generateError;
  final validated = <String>[];

  @override
  Future<DeliveryCode> generate(String orderId) async {
    if (generateError case final message?) {
      throw ApiException(message, statusCode: 400);
    }
    return DeliveryCode(code: '135790', expiresAt: expiresAt);
  }

  @override
  Future<Order> validate(String orderId, String code) async {
    validated.add(code);
    if (code != '135790') {
      throw const ApiException(
        'El código es inválido, ya se usó o venció.',
        statusCode: 400,
      );
    }
    return _order(status: OrderStatus.delivered);
  }
}

Future<void> _openReceive(WidgetTester tester, _FakeDelivery fake) async {
  final router = GoRouter(
    initialLocation: '/delivery/o1',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const Text('INICIO')),
      GoRoute(
        path: '/delivery/:orderId',
        builder: (_, state) =>
            ReceiveOrderScreen(orderId: state.pathParameters['orderId']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deliveryRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  test('el código lee su vencimiento y cuenta lo que falta', () {
    final code = DeliveryCode.fromJson({
      'code': '123456',
      'expiresAt': '2026-10-19T15:05:00.000Z',
    });
    expect(code.code, '123456');
    final now = DateTime.utc(2026, 10, 19, 15, 1, 30);
    expect(code.remaining(now), const Duration(minutes: 3, seconds: 30));
    expect(code.remaining(now.add(const Duration(hours: 1))), Duration.zero);
  });

  test('el tramo de regreso no cuenta como llegada', () {
    final back = Telemetry.fromJson({
      'orderId': 'o1',
      'droneId': 'd1',
      'identifier': 'D-01',
      'latitude': 10.46,
      'longitude': -73.25,
      'altitudeM': 100,
      'speedKmh': 90,
      'phase': 'landed',
      'leg': 'return',
      'status': 'returned',
      'etaSeconds': null,
    });
    expect(back.returning, isTrue);
    expect(back.arrived, isFalse);
  });

  test('el traslado lo recibe solo la central de destino', () {
    expect(
      DispatcherPermissions(order: _order(), myHubId: 'h2').canReceive,
      isTrue,
    );
    expect(
      DispatcherPermissions(order: _order(), myHubId: 'h1').canReceive,
      isFalse,
      reason: 'la central de origen no recibe',
    );
    expect(
      DispatcherPermissions(
        order: _order(status: OrderStatus.inFlight),
        myHubId: 'h2',
      ).canReceive,
      isFalse,
      reason: 'todavía no aterriza',
    );
  });

  testWidgets('en retorno el mapa avisa que el dron vuelve con el paquete', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlightNotice(
            state: TrackingState(loading: false, status: OrderStatus.returning),
          ),
        ),
      ),
    );
    expect(find.textContaining('vuelve a la central con'), findsOneWidget);
  });

  testWidgets('código equivocado avisa; el correcto entrega el pedido', (
    tester,
  ) async {
    final fake = _FakeDelivery(
      expiresAt: DateTime.now().add(const Duration(minutes: 4)),
    );
    await _openReceive(tester, fake);

    expect(find.text('1 3 5 7 9 0'), findsOneWidget);
    expect(find.textContaining('Vence en'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '111111');
    await tester.tap(find.text('Recibir pedido').last);
    await tester.pump();
    await tester.pump();
    expect(find.text('El código es inválido, ya se usó o venció.'), findsOne);

    await tester.enterText(find.byType(TextField), '135790');
    await tester.tap(find.text('Recibir pedido').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(fake.validated, ['111111', '135790']);
    expect(find.text('INICIO'), findsOneWidget);
  });

  testWidgets('sin código a tiempo la espera vence y no deja recibir', (
    tester,
  ) async {
    final fake = _FakeDelivery(
      expiresAt: DateTime.now().add(const Duration(seconds: 2)),
    );
    await _openReceive(tester, fake);
    expect(find.text('1 3 5 7 9 0'), findsOneWidget);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(ReceiveOrderScreen.expiredMessage), findsOneWidget);
    expect(find.text('1 3 5 7 9 0'), findsNothing);
    await tester.tap(find.text('Recibir pedido').last);
    await tester.pump();
    expect(fake.validated, isEmpty);
  });

  testWidgets('si Nest no da el código, se ve su mensaje', (tester) async {
    final fake = _FakeDelivery(
      expiresAt: DateTime.now(),
      generateError: 'El tiempo para recibir el pedido venció.',
    );
    await _openReceive(tester, fake);
    expect(
      find.text('El tiempo para recibir el pedido venció.'),
      findsOneWidget,
    );
  });
}
