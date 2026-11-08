import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fleet/data/fleet_flight.dart';
import 'package:frontend/features/fleet/data/fleet_map_models.dart';
import 'package:frontend/features/fleet/presentation/widgets/fleet_map/drone_facts_sheet.dart';
import 'package:frontend/features/fleet/presentation/widgets/fleet_map/fleet_map_sheet.dart';
import 'package:frontend/theme/app_theme.dart';

/// Como lo manda `GET /fleet/map` (§16).
final _json = <String, dynamic>{
  'hubs': [
    {
      'id': 'h1',
      'name': 'Hospital Rosario Pumarejo',
      'type': 'hospital',
      'status': 'active',
      'latitude': 10.46314,
      'longitude': -73.25322,
      'fleet': {
        'available': 1,
        'inMission': 1,
        'maintenance': 1,
        'outOfService': 0,
        'grounded': 0,
        'total': 3,
      },
    },
  ],
  'geofences': [
    {
      'id': 'g1',
      'name': 'Parque de la Leyenda',
      'reason': 'Evento',
      'polygon': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.26, 10.49],
            [-73.25, 10.49],
            [-73.25, 10.50],
            [-73.26, 10.49],
          ],
        ],
      },
    },
  ],
  'flights': [
    {
      'droneId': 'd1',
      'identifier': 'WG-198-001',
      'hubId': 'h1',
      'orderId': 'o1',
      'orderStatus': 'in_flight',
      'requiresColdChain': true,
      'phase': 'cruise',
      'leg': 'outbound',
      'latitude': 10.47,
      'longitude': -73.25,
      'altitudeM': 100,
      'speedKmh': 90,
      'batteryPercent': 78,
      'payloadKg': 0.4,
      'latencyMs': 42,
      'etaSeconds': 200,
      'alerts': {'battery': false, 'failure': false, 'coldChain': false},
      'route': {
        'coordinates': [
          [-73.25322, 10.46314],
          [-73.24, 10.48],
        ],
      },
      'returnRoute': null,
    },
  ],
};

void main() {
  test('lee el mapa: centrales con su flota, geovallas y vuelos', () {
    final map = FleetMap.fromJson(_json);
    expect(map.hubs.single.fleetLine, '3 drones · 1 en misión · 1 en taller');
    expect(map.geofences.single.polygon.ring, hasLength(4));
    final flight = map.flights.single;
    expect(flight.hasPosition, isTrue);
    expect(flight.activeRoute, hasLength(2));
  });

  test('un tick mueve el dron sin perder su ruta', () {
    final flight = FleetMap.fromJson(_json).flights.single;
    final moved = flight.withTick(
      FleetTick.fromJson({
        'orderId': 'o1',
        'latitude': 10.475,
        'longitude': -73.245,
        'altitudeM': 100,
        'speedKmh': 88,
        'phase': 'cruise',
        'leg': 'outbound',
        'batteryPercent': 76,
        'linkLost': true,
      }),
    );
    expect(moved.latitude, 10.475);
    expect(moved.batteryPercent, 76);
    expect(moved.linkLost, isTrue);
    expect(moved.route, flight.route);
  });

  test('la ficha del dron no trae nada del pedido', () {
    final facts = droneFacts(FleetMap.fromJson(_json).flights.single);
    final labels = [for (final (label, _) in facts) label];
    expect(labels, containsAll(['Fase', 'Batería', 'Altitud', 'Latencia']));
    expect(labels, isNot(contains('Dirección')));
    expect(labels, isNot(contains('Medicamento')));
  });

  testWidgets('la hoja muestra el incidente, la central y el vuelo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final incident = FleetIncident.fromJson({
      'id': 'i1',
      'droneId': 'd2',
      'protocol': 'emergency_landing',
      'outcome': 'grounded',
      'landingLatitude': 10.48,
      'landingLongitude': -73.24,
      'rescueDueAt': '2026-11-07T20:40:00.000Z',
      'resolvedAt': null,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ListView(
              children: fleetMapSheet(
                context: context,
                map: FleetMap.fromJson(_json),
                incidents: [incident],
                onFlight: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(incident.isOpen, isTrue);
    expect(find.textContaining('Aterrizaje de emergencia'), findsOneWidget);
    expect(find.textContaining('Hospital Rosario Pumarejo'), findsOneWidget);
    expect(find.text('WG-198-001'), findsOneWidget);
  });
}
