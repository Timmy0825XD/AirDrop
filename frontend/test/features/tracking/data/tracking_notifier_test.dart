import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/tracking/data/telemetry_client.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';

import '../../auth/presentation/auth_controller_test.dart' show FakeTokenStore;
import 'telemetry_models_test.dart' show mapView;

/// Cliente sin red: el GET devuelve [first] y el socket es un stream que el
/// test controla.
class FakeTelemetryClient extends TelemetryClient {
  FakeTelemetryClient(this.first)
    : super(
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
        baseUrl: 'http://test',
      );

  final Telemetry? first;
  final socket = StreamController<TelemetryEvent>();

  @override
  Future<Telemetry?> snapshot(String orderId) async => first;

  @override
  Stream<TelemetryEvent> watch(String orderId, {required String? token}) =>
      socket.stream;
}

void main() {
  late FakeTelemetryClient client;
  late ProviderContainer container;

  Future<TrackingState> start(Telemetry? first) async {
    client = FakeTelemetryClient(first);
    container = ProviderContainer(
      overrides: [
        telemetryClientProvider.overrideWithValue(client),
        tokenStoreProvider.overrideWithValue(FakeTokenStore()..value = 't'),
      ],
    );
    addTearDown(container.dispose);
    container.listen(trackingProvider('o1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return container.read(trackingProvider('o1'));
  }

  test('sin vuelo todavía: "está por empezar", no es un error', () async {
    final state = await start(null);
    expect(state.loading, isFalse);
    expect(state.waitingForFlight, isTrue);
    expect(state.problem, isNull);
  });

  test('cada telemetry del socket mueve el dron y el estado', () async {
    await start(Telemetry.fromJson(mapView()));
    client.socket
      ..add(const ConnectionChanged(connected: true))
      ..add(
        TelemetryReceived(
          Telemetry.fromJson(mapView(phase: 'descent', eta: 30)),
        ),
      )
      ..add(const StatusChanged(OrderStatus.awaitingDelivery));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(trackingProvider('o1'));
    expect(state.connected, isTrue);
    expect(state.telemetry!.phase, FlightPhase.descent);
    expect(state.status, OrderStatus.awaitingDelivery);
  });

  test('si el servidor niega la suscripción, se muestra su mensaje', () async {
    await start(Telemetry.fromJson(mapView()));
    client.socket.add(const SubscriptionRefused('El pedido no existe.'));
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(trackingProvider('o1')).problem,
      'El pedido no existe.',
    );
  });

  test(
    'una falla inesperada muestra un mensaje, no se queda cargando',
    () async {
      container = ProviderContainer(
        overrides: [
          telemetryClientProvider.overrideWithValue(_BrokenClient()),
          tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(trackingProvider('o1'), (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(trackingProvider('o1'));
      expect(state.loading, isFalse);
      expect(state.problem, 'No se pudo abrir el vuelo. Intenta de nuevo.');
    },
  );
}

class _BrokenClient extends FakeTelemetryClient {
  _BrokenClient() : super(null);

  @override
  Future<Telemetry?> snapshot(String orderId) async =>
      throw StateError('algo raro');
}
