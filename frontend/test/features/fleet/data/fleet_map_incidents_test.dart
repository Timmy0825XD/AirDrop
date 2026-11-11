import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/fleet/data/fleet_events.dart';
import 'package:frontend/features/fleet/data/fleet_map_models.dart';
import 'package:frontend/features/fleet/data/fleet_map_providers.dart';
import 'package:frontend/features/fleet/data/fleet_providers.dart';
import 'package:frontend/features/fleet/data/fleet_repository.dart';
import 'package:frontend/features/fleet/presentation/widgets/fleet_map/fleet_map_sheet.dart';
import 'package:frontend/features/tracking/data/telemetry_client.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/theme/app_theme.dart';

import '../../auth/presentation/auth_controller_test.dart' show FakeTokenStore;

/// Un incidente como lo manda `GET /fleet/map` en `incidents` (§18.1) y
/// `hub-incident` (§17).
Map<String, dynamic> incidentJson({
  String id = 'i1',
  String kind = 'dual_motor_failure',
  String outcome = 'grounded',
  String? resolvedAt,
}) => {
  'id': id,
  'orderId': 'o1',
  'droneId': 'd1',
  'hubId': 'h1',
  'kind': kind,
  'severity': 'major',
  'leg': 'outbound',
  'protocol': 'emergency_landing',
  'outcome': outcome,
  'latitude': 10.47,
  'longitude': -73.25,
  'batteryPercent': 61.6,
  'landingLatitude': 10.48,
  'landingLongitude': -73.24,
  'rescueDueAt': '2026-11-10T20:40:00.000Z',
  'packageOnBoard': true,
  'packageLost': false,
  'occurredAt': '2026-11-10T20:10:00.000Z',
  'resolvedAt': resolvedAt,
};

Map<String, dynamic> mapJson(List<Map<String, dynamic>> incidents) => {
  'hubs': [
    {
      'id': 'h1',
      'name': 'Hospital Rosario Pumarejo',
      'type': 'hospital',
      'status': 'active',
      'latitude': 10.46,
      'longitude': -73.25,
      'fleet': {'total': 1},
    },
  ],
  'geofences': const [],
  'flights': const [],
  'incidents': incidents,
};

const _kinds = [
  'battery_critical',
  'wind_limit',
  'route_blocked',
  'battery_short',
  'battery_degraded',
  'motor_failure',
  'dual_motor_failure',
  'gps_loss_minor',
  'gps_loss_major',
  'link_loss',
  'cooling_failure',
  'collision_minor',
  'collision_major',
  'drone_lost',
];

class _Repo implements FleetRepository {
  _Repo(this.maps);

  /// Lo que responde cada `GET /fleet/map`, en orden; el último se repite.
  final List<FleetMap> maps;
  var calls = 0;

  @override
  Future<FleetMap> fleetMap() async =>
      maps[(calls++).clamp(0, maps.length - 1)];

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
  group('FleetIncident', () {
    test('lee de /fleet/map el tipo, el tramo, la gravedad y el paquete', () {
      final map = FleetMap.fromJson(mapJson([incidentJson()]));
      final i = map.incidents.single;
      expect(i.orderId, 'o1');
      expect(i.kind, 'dual_motor_failure');
      expect(i.major, isTrue);
      expect(i.leg, 'outbound');
      expect(i.packageOnBoard, isTrue);
      expect(i.packageLost, isFalse);
      expect(i.batteryPercent, 61.6);
      expect(i.occurredAt, DateTime.utc(2026, 11, 10, 20, 10));
      // Dónde bajó, no dónde empezó el incidente.
      expect(i.latitude, 10.48);
      expect(i.isOpen, isTrue);
    });

    test('un mapa sin incidents (versión anterior de Nest) no falla', () {
      final json = mapJson(const [])..remove('incidents');
      expect(FleetMap.fromJson(json).incidents, isEmpty);
    });

    test('los 14 tipos tienen su propio texto', () {
      final labels = {
        for (final kind in _kinds)
          FleetIncident.fromJson(incidentJson(kind: kind)).kindLabel,
      };
      expect(labels, hasLength(14));
      expect(labels, isNot(contains('Incidente en vuelo')));
    });

    test('dice si el paquete se perdió, va a bordo o no había', () {
      FleetIncident with_(Map<String, dynamic> changes) =>
          FleetIncident.fromJson({...incidentJson(), ...changes});
      expect(with_({}).packageLabel, 'Con el paquete a bordo');
      expect(
        with_({'packageLost': true, 'kind': 'collision_major'}).packageLabel,
        'Paquete perdido',
      );
      expect(with_({'packageOnBoard': false}).packageLabel, 'Sin paquete');
    });
  });

  testWidgets('la hoja dice qué pasó, en qué tramo y cómo va', (tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final map = FleetMap.fromJson(mapJson([incidentJson()]));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ListView(
              children: fleetMapSheet(
                context: context,
                map: map,
                incidents: map.incidents,
                onFlight: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = incidentLine(map.incidents.single);
    expect(
      text,
      startsWith('Falla de 2 motores en la ida · Aterrizaje de emergencia.'),
    );
    expect(text, contains('En tierra, espera el rescate'));
    expect(text, contains('Con el paquete a bordo'));
    expect(text, contains('batería 62 %'));
    expect(find.text(text), findsOneWidget);
  });

  group('FleetMapNotifier', () {
    late _Client client;
    late _Repo repo;
    late ProviderContainer container;

    Future<void> start(List<FleetMap> maps) async {
      client = _Client();
      repo = _Repo(maps);
      container = ProviderContainer(
        overrides: [
          fleetRepositoryProvider.overrideWithValue(repo),
          telemetryClientProvider.overrideWithValue(client),
          tokenStoreProvider.overrideWithValue(FakeTokenStore()..value = 't'),
        ],
      );
      addTearDown(container.dispose);
      container.listen(fleetMapProvider, (_, _) {});
      await pumpEventQueue();
    }

    List<String> open() => [
      for (final i in container.read(fleetMapProvider).incidents) i.id,
    ];

    test('al abrir el mapa ya trae los incidentes abiertos', () async {
      await start([
        FleetMap.fromJson(mapJson([incidentJson(id: 'i2'), incidentJson()])),
      ]);
      expect(open(), ['i2', 'i1']);
    });

    test('el socket suma uno nuevo y quita el que se resolvió', () async {
      await start([
        FleetMap.fromJson(mapJson([incidentJson()])),
      ]);
      client.socket
        ..add(
          FleetIncidentReceived(
            FleetIncident.fromJson(incidentJson(id: 'i2', kind: 'link_loss')),
          ),
        )
        ..add(
          FleetIncidentReceived(
            FleetIncident.fromJson(
              incidentJson(
                outcome: 'rescued',
                resolvedAt: '2026-11-10T20:45:00.000Z',
              ),
            ),
          ),
        );
      await pumpEventQueue();
      expect(open(), ['i2']);
    });

    test('al recargar, manda lo que diga Nest', () async {
      await start([
        FleetMap.fromJson(mapJson([incidentJson()])),
        FleetMap.fromJson(mapJson(const [])),
      ]);
      await container.read(fleetMapProvider.notifier).refresh();
      expect(open(), isEmpty);
    });
  });
}
