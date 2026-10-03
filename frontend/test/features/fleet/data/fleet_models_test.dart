import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';

/// El contrato lo definen los DTO de `fleet` en Nest.
void main() {
  test('solo tres estados son manipulables desde la app', () {
    expect(DroneStatus.operatorStatuses, [
      DroneStatus.available,
      DroneStatus.maintenance,
      DroneStatus.outOfService,
    ]);
    expect(
      DroneStatus.operatorStatuses.contains(DroneStatus.inMission),
      isFalse,
      reason: 'in_mission lo asigna el motor de decisión, no la pantalla',
    );
    expect(DroneStatus.inMission.isInMission, isTrue);
    expect(DroneStatus.inMission.isOperable, isFalse);
  });

  test('el body del PATCH lleva el estado y omite lo vacío', () {
    const available = UpdateDroneStatusRequest(status: DroneStatus.available);
    expect(available.toJson(), {'status': 'available'});

    const withReason = UpdateDroneStatusRequest(
      status: DroneStatus.maintenance,
      reason: '   Cambio de hélices   ',
      estimatedEndDate: '',
    );
    expect(withReason.toJson(), {
      'status': 'maintenance',
      'reason': 'Cambio de hélices',
      // Una fecha en blanco no viaja: `Matches(/^\d{4}-\d{2}-\d{2}$/)`
      // la rechazaría en el DTO.
    });

    const blankReason = UpdateDroneStatusRequest(
      status: DroneStatus.maintenance,
      reason: '   ',
      estimatedEndDate: null,
    );
    expect(
      blankReason.toJson(),
      {'status': 'maintenance'},
      reason: 'un motivo en blanco solo ensuciaría el cuerpo',
    );
  });

  test('el body del POST de mantenimiento es obligatorio y recortado', () {
    const request = RegisterMaintenanceRequest(
      reason: '  Revisión de baterías  ',
      estimatedEndDate: '2026-11-30',
    );
    expect(request.toJson(), {
      'reason': 'Revisión de baterías',
      'estimatedEndDate': '2026-11-30',
    });
  });

  test('el alta manda identificador, modelo y central', () {
    const request = CreateDroneRequest(
      identifier: 'DRON-01',
      droneModelId: 'model-1',
      hubId: 'hub-1',
    );
    expect(request.toJson(), {
      'identifier': 'DRON-01',
      'droneModelId': 'model-1',
      'hubId': 'hub-1',
    });
  });

  test('Drone.fromJson lee el estado y la fecha de mantenimiento', () {
    final drone = Drone.fromJson({
      'id': 'd1',
      'identifier': 'DRON-01',
      'droneModelId': 'm1',
      'hubId': 'h1',
      'status': 'maintenance',
      'maintenanceReason': 'Cambio de hélices',
      'maintenanceUntil': '2026-10-15',
      'createdAt': '2026-09-01T12:00:00.000Z',
    });

    expect(drone.status, DroneStatus.maintenance);
    expect(drone.hasMaintenanceData, isTrue);
    expect(drone.maintenanceUntil, '2026-10-15');

    const bare = Drone(
      id: 'd2',
      identifier: 'DRON-02',
      droneModelId: 'm1',
      hubId: 'h1',
      status: DroneStatus.available,
    );
    expect(bare.hasMaintenanceData, isFalse);
  });

  test('un estado desconocido lanza FormatException', () {
    expect(
      () => DroneStatus.fromJson('flying'),
      throwsA(isA<FormatException>()),
    );
  });
}
