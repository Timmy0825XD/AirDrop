import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_tile.dart';
import 'package:frontend/features/fleet/presentation/widgets/fleet_list_values.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/theme/app_theme.dart';

const _hubs = [
  Hub(
    id: 'h1',
    name: 'Central La Paz',
    type: HubType.hospital,
    address: 'La Paz',
    latitude: 10.38,
    longitude: -73.17,
    contactPhone: '3001234567',
    status: HubStatus.active,
  ),
  Hub(
    id: 'h2',
    name: 'Central San Diego',
    type: HubType.hospital,
    address: 'San Diego',
    latitude: 10.33,
    longitude: -73.18,
    contactPhone: '3001234567',
    status: HubStatus.active,
  ),
];
const _models = [
  DroneModel(
    id: 'm1',
    code: 'rapid',
    name: 'Colibrí',
    maxSpeedKmh: 140,
    maxPayloadKg: 2,
    maxRangeKm: 120,
  ),
];
Drone _drone(String id, DroneStatus status) => Drone(
  id: id,
  identifier: 'CL-$id',
  droneModelId: 'm1',
  hubId: 'h1',
  status: status,
  batteryPercent: 96,
);
FleetListValues _data(
  List<Drone> rows, {
  String query = '',
  FleetFilter filter = FleetFilter.all,
  Hub hub = _defaultHub,
}) => FleetListValues(
  hubs: const AsyncData(_hubs),
  hub: hub,
  drones: AsyncData(rows),
  models: const AsyncData(_models),
  query: query,
  filter: filter,
);
const _defaultHub = Hub(
  id: 'h1',
  name: 'Central La Paz',
  type: HubType.hospital,
  address: 'La Paz',
  latitude: 10.38,
  longitude: -73.17,
  contactPhone: '3001234567',
  status: HubStatus.active,
);

void main() {
  test('busca por identificador y nombre del modelo sin tildes', () {
    final rows = [
      _drone('01', DroneStatus.available),
      _drone('02', DroneStatus.maintenance),
    ];
    expect(_data(rows, query: 'cl-02').shown.single.id, '02');
    expect(_data(rows, query: 'colibri').shown.length, 2);
    expect(
      _data(
        rows,
        query: '  COLIBRÍ  ',
        filter: FleetFilter.available,
      ).shown.single.id,
      '01',
    );
  });
  test(
    'Todos conserva fuera de servicio y rescate; los filtros son independientes',
    () {
      final rows = [
        _drone('01', DroneStatus.available),
        _drone('02', DroneStatus.inMission),
        _drone('03', DroneStatus.maintenance),
        _drone('04', DroneStatus.outOfService),
        _drone('05', DroneStatus.grounded),
      ];
      expect(_data(rows).shown.length, 5);
      expect(_data(rows, filter: FleetFilter.inMission).shown.single.id, '02');
      expect(
        _data(rows, filter: FleetFilter.maintenance).shown.single.id,
        '03',
      );
    },
  );
  test(
    'al cambiar de central no presenta ni permite operar los drones anteriores',
    () {
      final state = _data([_drone('01', DroneStatus.available)], hub: _hubs[1]);
      expect(state.rows, isNull);
      expect(state.shown, isEmpty);
      expect(state.loadingDrones, isTrue);
    },
  );
  testWidgets('un dron en misión abre su vuelo y no ofrece Gestionar', (
    tester,
  ) async {
    var flights = 0, changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: DroneTile(
            drone: _drone('02', DroneStatus.inMission),
            modelName: 'Colibrí',
            onActions: () => changes++,
            onFlight: () => flights++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gestionar'), findsNothing);
    await tester.tap(find.text('Ver vuelo'));
    expect(flights, 1);
    expect(changes, 0);
  });
}
