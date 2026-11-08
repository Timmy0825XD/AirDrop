import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_health.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_status_sheet.dart';
import 'package:frontend/theme/app_theme.dart';

Drone _drone(DroneStatus status, {bool due = false, bool overdue = false}) =>
    Drone(
      id: 'd1',
      identifier: 'DRON-01',
      droneModelId: 'm1',
      hubId: 'h1',
      status: status,
      batteryPercent: 86,
      flightsSinceMaintenance: 42,
      maintenanceCycles: 50,
      maintenanceDue: due,
      maintenanceOverdue: overdue,
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

final DroneActions _noop = (
  setAvailable: () {},
  sendToMaintenance: () {},
  putOutOfService: () {},
  viewHistory: () {},
);

void main() {
  test('lee batería, vuelos y marcas de taller de Nest', () {
    final drone = Drone.fromJson({
      'id': 'd1',
      'identifier': 'DRON-01',
      'droneModelId': 'm1',
      'hubId': 'h1',
      'status': 'maintenance',
      'batteryPercent': 92.5,
      'lastFlightEndedAt': null,
      'flightsSinceMaintenance': 50,
      'maintenanceCycles': 50,
      'maintenanceDue': true,
      'maintenanceOverdue': true,
    });
    expect(drone.batteryPercent, 92.5);
    expect(drone.lastFlightEndedAt, isNull);
    expect(drone.maintenanceDue, isTrue);
    expect(drone.maintenanceOverdue, isTrue);

    final period = MaintenancePeriod.fromJson({
      'id': 'p1',
      'kind': 'out_of_service',
      'reason': 'Ala rota',
      'estimatedEndDate': null,
      'flightsAtStart': 12,
      'startedAt': '2026-11-05T15:00:00.000Z',
      'closedAt': null,
    });
    expect(period.kind, MaintenanceKind.outOfService);
    expect(period.isOpen, isTrue);
  });

  test('dice cuándo volvió el dron de su último vuelo', () {
    final now = DateTime(2026, 11, 7, 10);
    expect(lastFlightLabel(null, now), 'Nunca ha volado');
    expect(
      lastFlightLabel(now.subtract(const Duration(minutes: 12)), now),
      'Volvió hace 12 min',
    );
    expect(
      lastFlightLabel(now.subtract(const Duration(hours: 3)), now),
      'Volvió hace 3 h',
    );
  });

  testWidgets('la fila marca la revisión y el vencido', (tester) async {
    await _pump(tester, DroneHealth(drone: _drone(DroneStatus.available)));
    expect(find.textContaining('42 / 50 vuelos'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('Le toca revisión'), findsNothing);

    await _pump(
      tester,
      DroneHealth(drone: _drone(DroneStatus.available, due: true)),
    );
    expect(find.text('Le toca revisión'), findsOneWidget);

    await _pump(
      tester,
      DroneHealth(
        drone: _drone(DroneStatus.maintenance, due: true, overdue: true),
      ),
    );
    expect(find.text('Mantenimiento vencido'), findsOneWidget);
    expect(find.text('Le toca revisión'), findsNothing);
  });

  testWidgets('"Gestionar" ofrece solo lo que aplica a cada estado', (
    tester,
  ) async {
    await _pump(
      tester,
      DroneStatusSheet(drone: _drone(DroneStatus.available), actions: _noop),
    );
    expect(find.text('Marcar disponible'), findsNothing);
    expect(find.text('Enviar a mantenimiento'), findsOneWidget);
    expect(find.text('Dejar fuera de servicio'), findsOneWidget);
    expect(find.text('Ver historial de taller'), findsOneWidget);

    await _pump(
      tester,
      DroneStatusSheet(drone: _drone(DroneStatus.maintenance), actions: _noop),
    );
    expect(find.text('Marcar disponible'), findsOneWidget);
    expect(find.text('Enviar a mantenimiento'), findsNothing);
    expect(find.text('Dejar fuera de servicio'), findsOneWidget);

    await _pump(
      tester,
      DroneStatusSheet(drone: _drone(DroneStatus.outOfService), actions: _noop),
    );
    expect(find.text('Marcar disponible'), findsOneWidget);
    expect(find.text('Enviar a mantenimiento'), findsOneWidget);
    expect(find.text('Dejar fuera de servicio'), findsNothing);
  });
}
