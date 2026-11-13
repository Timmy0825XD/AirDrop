import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/fleet/data/fleet_events.dart';
import 'package:frontend/features/fleet/data/fleet_map_models.dart';
import 'package:frontend/features/fleet/data/fleet_map_providers.dart';
import 'package:frontend/features/fleet/data/fleet_providers.dart';
import 'package:frontend/features/fleet/data/fleet_repository.dart';
import 'package:frontend/features/fleet/presentation/widgets/fleet_map/reroute_notice.dart';
import 'package:frontend/features/tracking/data/telemetry_client.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';

import '../../auth/presentation/auth_controller_test.dart' show FakeTokenStore;
import 'fleet_map_incidents_test.dart' show mapJson;

/// `hub-reroute` como lo manda Nest (§18.2).
Map<String, dynamic> rerouteJson({
  String outcome = 'rerouted',
  double? addedKm = 1.24,
  bool batteryShort = false,
}) => {
  'hubId': 'h1',
  'orderId': 'o1',
  'droneId': 'd1',
  'outcome': outcome,
  'addedKm': addedKm,
  'crossesGeofence': outcome == 'blocked',
  'batteryShort': batteryShort,
};

class _Repo implements FleetRepository {
  var calls = 0;

  @override
  Future<FleetMap> fleetMap() async {
    calls++;
    return FleetMap.fromJson(mapJson(const []));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client extends TelemetryClient {
  _Client()
    : super(
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
        baseUrl: 'http://test',
      );

  final socket = StreamController<FleetEvent>();

  @override
  Stream<FleetEvent> watchFleet(String hubId, {required String? token}) =>
      socket.stream;
}

void main() {
  group('FleetReroute', () {
    test('lee la ruta nueva y cuánto se alarga', () {
      final r = FleetReroute.fromJson(rerouteJson());
      expect(r.orderId, 'o1');
      expect(r.droneId, 'd1');
      expect(r.blocked, isFalse);
      expect(r.addedKm, 1.24);
      expect(r.needsAttention, isFalse);
    });

    test('sin camino o sin batería pide atención', () {
      final blocked = FleetReroute.fromJson(
        rerouteJson(outcome: 'blocked', addedKm: null),
      );
      expect(blocked.blocked, isTrue);
      expect(blocked.addedKm, isNull);
      expect(blocked.needsAttention, isTrue);
      expect(
        FleetReroute.fromJson(rerouteJson(batteryShort: true)).needsAttention,
        isTrue,
      );
    });
  });

  group('rerouteMessage', () {
    test('ruta cambiada con los km de más', () {
      final r = FleetReroute.fromJson(rerouteJson());
      expect(rerouteMessage(r), 'Ruta cambiada (+1,2 km)');
      expect(
        rerouteMessage(r, drone: 'WC-01'),
        'WC-01: ruta cambiada (+1,2 km)',
      );
    });

    test('un desvío mínimo no dice +0,0 km', () {
      final r = FleetReroute.fromJson(rerouteJson(addedKm: 0));
      expect(rerouteMessage(r), 'Ruta cambiada');
    });

    test('avisa si la batería no alcanza', () {
      final r = FleetReroute.fromJson(rerouteJson(batteryShort: true));
      expect(
        rerouteMessage(r),
        'Ruta cambiada (+1,2 km); la batería no alcanza con la reserva',
      );
    });

    test('sin camino seguro', () {
      final r = FleetReroute.fromJson(
        rerouteJson(outcome: 'blocked', addedKm: null),
      );
      expect(rerouteMessage(r), 'Sin ruta segura, el dron sigue el protocolo');
    });
  });

  test('el mapa guarda el aviso y vuelve a pedir la ruta nueva', () async {
    final client = _Client();
    final repo = _Repo();
    final container = ProviderContainer(
      overrides: [
        fleetRepositoryProvider.overrideWithValue(repo),
        telemetryClientProvider.overrideWithValue(client),
        tokenStoreProvider.overrideWithValue(FakeTokenStore()..value = 't'),
      ],
    );
    addTearDown(container.dispose);
    container.listen(fleetMapProvider, (_, _) {});
    await pumpEventQueue();
    expect(repo.calls, 1);

    client.socket.add(
      FleetRerouteReceived(FleetReroute.fromJson(rerouteJson())),
    );
    await pumpEventQueue();

    expect(container.read(fleetMapProvider).reroute?.addedKm, 1.24);
    expect(repo.calls, 2);
  });
}
