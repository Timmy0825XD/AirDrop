import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/data/queue_live.dart';
import 'package:frontend/features/tracking/data/telemetry_client.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';

import '../auth/presentation/auth_controller_test.dart' show FakeTokenStore;

/// Cliente sin red: la sala de la central es un stream que el test controla.
class FakeQueueClient extends TelemetryClient {
  FakeQueueClient()
    : super(
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
        baseUrl: 'http://test',
      );

  final rooms = <String>[];
  final changes = StreamController<void>.broadcast();
  var cancelled = 0;

  @override
  Stream<void> watchQueue(String hubId, {required String? token}) {
    rooms.add(hubId);
    late final StreamController<void> socket;
    socket = StreamController<void>(onCancel: () => cancelled++);
    changes.stream.listen((_) => socket.add(null));
    return socket.stream;
  }
}

const _hub = Hub(
  id: 'hub-a',
  name: 'Hospital Rosario Pumarejo',
  type: HubType.hospital,
  address: 'Calle 16 No. 19-35',
  latitude: 10.46,
  longitude: -73.25,
  contactPhone: '3001234567',
  status: HubStatus.active,
);

void main() {
  late FakeQueueClient client;
  late ProviderContainer container;
  late int loads;

  Future<void> start({Hub? hub = _hub}) async {
    client = FakeQueueClient();
    loads = 0;
    container = ProviderContainer(
      overrides: [
        telemetryClientProvider.overrideWithValue(client),
        tokenStoreProvider.overrideWithValue(FakeTokenStore()..value = 't'),
        myHubProvider.overrideWith((ref) async => hub),
        queueProvider.overrideWith((ref) async {
          loads++;
          return const <QueueEntry>[];
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(queueProvider, (_, _) {});
    await container.read(myHubProvider.future);
    container.listen(queueLiveProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await container.read(queueProvider.future);
  }

  test('se suscribe a la sala de su central', () async {
    await start();
    expect(client.rooms, ['hub-a']);
  });

  test('cada queue-changed vuelve a pedir la cola', () async {
    await start();
    final before = loads;
    client.changes.add(null);
    await settle();
    expect(loads, before + 1);
    client.changes.add(null);
    await settle();
    expect(loads, before + 2);
  });

  test('sin central no abre el socket', () async {
    await start(hub: null);
    expect(client.rooms, isEmpty);
  });

  test('al dejar de escucharla se cierra el socket', () async {
    await start();
    container.dispose();
    expect(client.cancelled, 1);
  });
}
