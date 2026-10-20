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

/// Nest de mentira: el código es `135790`. [expiresAt] `null` = el dron
/// todavía vuela. Al quinto código equivocado se bloquea, como Nest.
class _FakeDelivery implements DeliveryRepository {
  _FakeDelivery({this.expiresAt, this.codeError});

  DateTime? expiresAt;
  final String? codeError;
  final validated = <String>[];
  int reads = 0;
  int _wrong = 0;

  @override
  Future<DeliveryCode> code(String orderId) async {
    reads++;
    if (codeError case final message?) {
      throw ApiException(message, statusCode: 400);
    }
    return DeliveryCode(code: '135790', expiresAt: expiresAt);
  }

  @override
  Future<Order> validate(String orderId, String code) async {
    validated.add(code);
    if (_wrong >= 5) {
      throw const ApiException(
        ReceiveOrderScreen.lockedMessage,
        statusCode: 400,
      );
    }
    if (code != '135790') {
      _wrong++;
      throw ApiException(
        _wrong >= 5
            ? ReceiveOrderScreen.lockedMessage
            : 'El código es inválido, ya se usó o venció.',
        statusCode: 400,
      );
    }
    return _order(status: OrderStatus.delivered);
  }
}

Future<void> _type(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.tap(find.text('Confirmar entrega'));
  await tester.pump();
  await tester.pump();
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
        order: _order(status: OrderStatus.received),
        myHubId: 'h2',
      ).canReceive,
      isFalse,
      reason: 'sin carga confirmada no hay código',
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

  testWidgets('en vuelo se ve el código; al aterrizar se puede escribir', (
    tester,
  ) async {
    final fake = _FakeDelivery();
    await _openReceive(tester, fake);

    expect(find.text('1 3 5 7 9 0'), findsOneWidget);
    expect(find.textContaining('va en camino'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // El dron aterriza: la siguiente lectura (cada 10 s) trae el límite.
    fake.expiresAt = DateTime.now().add(const Duration(minutes: 4));
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(fake.reads, 2);
    expect(find.textContaining('Vence en'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('código equivocado avisa; el correcto entrega el pedido', (
    tester,
  ) async {
    final fake = _FakeDelivery(
      expiresAt: DateTime.now().add(const Duration(minutes: 4)),
    );
    await _openReceive(tester, fake);

    await _type(tester, '111111');
    expect(find.text('El código es inválido, ya se usó o venció.'), findsOne);

    await _type(tester, '135790');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(fake.validated, ['111111', '135790']);
    expect(find.text('INICIO'), findsOneWidget);
  });

  testWidgets('al quinto código equivocado se apaga el botón', (tester) async {
    final fake = _FakeDelivery(
      expiresAt: DateTime.now().add(const Duration(minutes: 4)),
    );
    await _openReceive(tester, fake);

    for (var i = 0; i < 5; i++) {
      await _type(tester, '00000$i');
    }

    expect(find.text(ReceiveOrderScreen.lockedMessage), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Confirmar entrega'));
    await tester.pump();
    expect(fake.validated, hasLength(5));
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
    await tester.tap(find.text('Confirmar entrega'));
    await tester.pump();
    expect(fake.validated, isEmpty);
  });

  testWidgets('si Nest no da el código, se ve su mensaje', (tester) async {
    final fake = _FakeDelivery(
      codeError: 'El código aparece cuando el despachador confirma la carga.',
    );
    await _openReceive(tester, fake);
    expect(
      find.text('El código aparece cuando el despachador confirma la carga.'),
      findsOneWidget,
    );
  });

  test('el código en vuelo no trae límite', () {
    final code = DeliveryCode.fromJson({'code': '123456', 'expiresAt': null});
    expect(code.landed, isFalse);
    expect(code.remaining(DateTime.now()), isNull);
  });
}
