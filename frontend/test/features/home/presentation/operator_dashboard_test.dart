import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fleet/data/fleet_dashboard_models.dart';
import 'package:frontend/features/home/presentation/widgets/operator/fleet_incidents_card.dart';
import 'package:frontend/features/home/presentation/widgets/operator/operator_dashboard.dart';
import 'package:frontend/theme/app_theme.dart';

/// El ejemplo de §16 de `pendientes-backend.md`.
final _json = <String, dynamic>{
  'period': {'from': '2026-10-07', 'to': '2026-11-05'},
  'usage': {
    'flights': 18,
    'km': 86.4,
    'inMissionPercent': 12.5,
    'inShopPercent': 4,
    'availablePercent': 83.5,
    'byDrone': [],
  },
  'health': {
    'landingBattery': {'average': 61.2, 'min': 38, 'samples': 18},
    'maintenanceDue': 1,
    'maintenanceOverdue': 0,
    'byDrone': [],
  },
  'incidents': {
    'battery': 1,
    'failure': 0,
    'coldChain': 2,
    'returnedWithPackage': 1,
    'byDrone': [
      {
        'droneId': 'd1',
        'identifier': 'WG-198-001',
        'battery': 1,
        'failure': 0,
        'coldChain': 1,
        'returnedWithPackage': 0,
      },
    ],
    'byDay': [
      {
        'date': '2026-11-04',
        'flights': 3,
        'battery': 0,
        'failure': 0,
        'coldChain': 1,
        'returnedWithPackage': 0,
      },
    ],
  },
  'zones': {
    'flights': [],
    'geofenceBlocks': {'total': 0, 'zones': []},
  },
};

void main() {
  test('lee el tablero de Nest', () {
    final d = FleetDashboard.fromJson(_json);
    expect(d.flights, 18);
    expect(d.km, 86.4);
    expect(d.landingBatteryAverage, 61.2);
    expect(d.maintenanceDue, 1);
    expect(d.incidents.total, 4);
    expect(d.incidentsByDrone.single.label, 'WG-198-001');
    expect(
      incidentBreakdown(d.incidents),
      '1 de batería · 2 de frío · 1 volvió con el paquete',
    );
  });

  test('sin muestras de batería no inventa un promedio', () {
    final d = FleetDashboard.fromJson({
      'health': {
        'landingBattery': {'average': 0, 'min': 0, 'samples': 0},
      },
    });
    expect(d.landingBatteryAverage, isNull);
    expect(incidentBreakdown(d.incidents), 'Sin incidentes en el periodo.');
  });

  testWidgets('el tablero se ve completo en 360 px', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OperatorDashboard(
              state: AsyncData(FleetDashboard.fromJson(_json)),
              onOpenFleet: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('18 vuelos · 86,4 km'), findsOneWidget);
    expect(find.textContaining('61 % de batería en promedio'), findsOneWidget);
    expect(find.text('1 pide revisión'), findsOneWidget);
    expect(find.textContaining('WG-198-001'), findsOneWidget);

    await tester.tap(find.text('Salud de la flota'));
    expect(opened, isTrue);
  });
}
