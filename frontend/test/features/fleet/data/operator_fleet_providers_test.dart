import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fleet/data/fleet_flight.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/data/fleet_providers.dart';
import 'package:frontend/features/fleet/data/fleet_repository.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/hubs/data/hub_repository.dart';
import 'package:frontend/features/orders/data/order_models.dart';

/// Un operador con dos centrales: el dron en misión vive en la segunda.
class _TwoHubs extends Fake implements HubRepository {
  @override
  Future<List<Hub>> list({HubStatus? status}) async => [
    _hub('hub-1', 'Hospital Rosario'),
    _hub('hub-2', 'Clínica del Cesar'),
  ];
}

class _FleetByHub extends Fake implements FleetRepository {
  @override
  Future<List<Drone>> listDrones(String hubId) async => switch (hubId) {
    'hub-1' => [_drone('d1', hubId, DroneStatus.available)],
    _ => [_drone('d2', hubId, DroneStatus.inMission)],
  };

  @override
  Future<List<FleetFlight>> listFlights(String hubId) async => switch (hubId) {
    'hub-2' => [
      FleetFlight(
        droneId: 'd2',
        identifier: 'DRON-d2',
        hubId: hubId,
        orderId: 'o1',
        orderStatus: OrderStatus.inFlight,
        requiresColdChain: false,
      ),
    ],
    _ => const [],
  };
}

Hub _hub(String id, String name) => Hub(
  id: id,
  name: name,
  type: HubType.hospital,
  address: 'Calle 15 # 12-45, Valledupar',
  latitude: 10.463140,
  longitude: -73.253220,
  contactPhone: '3001234567',
  status: HubStatus.active,
);

Drone _drone(String id, String hubId, DroneStatus status) => Drone(
  id: id,
  identifier: 'DRON-$id',
  droneModelId: 'm1',
  hubId: hubId,
  status: status,
);

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        hubRepositoryProvider.overrideWithValue(_TwoHubs()),
        fleetRepositoryProvider.overrideWithValue(_FleetByHub()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'el inicio del operador cuenta los drones de todas sus centrales',
    () async {
      final drones = await container().read(operatorDronesProvider.future);

      expect(drones.map((d) => d.id), ['d1', 'd2']);
      expect(
        drones.where((d) => d.status == DroneStatus.inMission),
        hasLength(1),
      );
    },
  );

  test('los vuelos en curso incluyen los de una central no elegida', () async {
    final flights = await container().read(fleetFlightsProvider.future);

    expect(flights.map((f) => f.hubId), ['hub-2']);
  });
}
