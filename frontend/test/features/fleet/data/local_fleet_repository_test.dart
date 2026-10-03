import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/local/local_auth_rules.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/data/local_fleet_repository.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_repository.dart';

/// Sesión simulada del operador de flota (`operador@airdrop.local`), la
/// única cuenta con la central de demostración asignada.
const String _operatorSession =
    '${LocalAuthRules.tokenPrefix}33333333-3333-4333-8333-333333333333';

const String _demoHubId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _wingcopterId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore([this.value]);

  final String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

class _FakeHubRepository implements HubRepository {
  _FakeHubRepository(this.hubs);

  final List<Hub> hubs;

  @override
  Future<Hub?> mine() async => hubs.isEmpty ? null : hubs.first;

  @override
  Future<List<Hub>> list({HubStatus? status}) async => hubs;

  @override
  Future<Hub> create(CreateHubRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Hub> setSuspension(String id, {required bool suspended}) async =>
      throw UnimplementedError();
}

Hub _hub({String id = _demoHubId, HubStatus status = HubStatus.active}) => Hub(
  id: id,
  name: 'Central Demo',
  type: HubType.hospital,
  address: 'Calle 15 # 12-45, Valledupar',
  latitude: 10.463140,
  longitude: -73.253220,
  contactPhone: '3001234567',
  status: status,
);

Drone _drone({
  String id = 'd1111111-1111-4111-8111-111111111111',
  String identifier = 'DRON-01',
  String hubId = _demoHubId,
  DroneStatus status = DroneStatus.available,
  String? reason,
  String? until,
}) => Drone(
  id: id,
  identifier: identifier,
  droneModelId: _wingcopterId,
  hubId: hubId,
  status: status,
  maintenanceReason: reason,
  maintenanceUntil: until,
);

LocalFleetRepository _repo({
  HubStatus hubStatus = HubStatus.active,
  String hubId = _demoHubId,
  List<Drone>? drones,
}) => LocalFleetRepository(
  hubRepository: _FakeHubRepository([
    _hub(id: hubId, status: hubStatus),
    // Central existente pero **sin** asignar al operador: hace falta
    // separarla de la de arriba para probar `assertAssigned`.
    _hub(id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  ]),
  tokenStore: _FakeTokenStore(_operatorSession),
  drones: drones,
);

/// Los mensajes y códigos son los de `FleetService` en Nest.
void main() {
  test('sin una sesión activa Nest responde 401, no 403', () async {
    final repo = LocalFleetRepository(
      hubRepository: _FakeHubRepository([_hub()]),
      tokenStore: _FakeTokenStore('local-session:otro-usuario'),
    );

    await expectLater(
      repo.listDrones(_demoHubId),
      _message(401, 'Tu sesión expiró. Inicia sesión de nuevo.'),
    );
  });

  test('el modelo de dron inexistente responde 404 con el mensaje de Nest', () async {
    final repo = _repo();

    await expectLater(
      repo.create(
        const CreateDroneRequest(
          identifier: 'DRON-09',
          droneModelId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
          hubId: _demoHubId,
        ),
      ),
      _message(404, 'El modelo de dron no existe.'),
    );
  });

  test('una central sin asignar responde 403 con el mensaje de Nest', () async {
    final repo = _repo();

    await expectLater(
      repo.create(
        const CreateDroneRequest(
          identifier: 'DRON-09',
          droneModelId: _wingcopterId,
          hubId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        ),
      ),
      _message(403, 'Esa central no está asignada a tu cuenta.'),
    );
  });

  test('una central suspendida bloquea el alta con 403', () async {
    final repo = _repo(hubStatus: HubStatus.suspended);

    await expectLater(
      repo.create(
        const CreateDroneRequest(
          identifier: 'DRON-09',
          droneModelId: _wingcopterId,
          hubId: _demoHubId,
        ),
      ),
      _message(403, 'La central está suspendida.'),
    );
  });

  test('un identificador repetido responde 409', () async {
    final repo = _repo();

    await expectLater(
      repo.create(
        const CreateDroneRequest(
          identifier: 'DRON-01',
          droneModelId: _wingcopterId,
          hubId: _demoHubId,
        ),
      ),
      _message(409, 'Ya existe un dron con este identificador.'),
    );
  });

  test('crear un dron lo deja disponible en la central elegida', () async {
    final repo = _repo();

    final drone = await repo.create(
      const CreateDroneRequest(
        identifier: '  DRON-09  ',
        droneModelId: _wingcopterId,
        hubId: _demoHubId,
      ),
    );

    expect(drone.identifier, 'DRON-09', reason: 'el identificador se recorta');
    expect(drone.status, DroneStatus.available);
    expect(drone.hubId, _demoHubId);
    // Ordenado por identificador, como `FleetService.listDrones`.
    final rows = await repo.listDrones(_demoHubId);
    expect(rows.map((drone) => drone.identifier), [
      'DRON-01',
      'DRON-02',
      'DRON-09',
    ]);
  });

  test('un dron en misión no admite cambios: 409 de Nest', () async {
    final repo = _repo(
      drones: [
        _drone(status: DroneStatus.inMission),
        _drone(
          id: 'd2222222-2222-4222-8222-222222222222',
          identifier: 'DRON-02',
          status: DroneStatus.maintenance,
          reason: 'Cambio de hélices',
          until: '2026-10-15',
        ),
      ],
    );

    await expectLater(
      repo.updateStatus(
        'd1111111-1111-4111-8111-111111111111',
        const UpdateDroneStatusRequest(status: DroneStatus.available),
      ),
      _message(409, 'No puedes cambiar el estado de un dron en misión.'),
    );
    await expectLater(
      repo.registerMaintenance(
        'd1111111-1111-4111-8111-111111111111',
        const RegisterMaintenanceRequest(
          reason: 'Revisión',
          estimatedEndDate: '2026-11-01',
        ),
      ),
      _message(409, 'No puedes cambiar el estado de un dron en misión.'),
    );
  });

  test('volver a disponible limpia motivo y fecha', () async {
    final repo = _repo(
      drones: [
        _drone(
          status: DroneStatus.maintenance,
          reason: 'Cambio de hélices',
          until: '2026-10-15',
        ),
      ],
    );

    final updated = await repo.updateStatus(
      'd1111111-1111-4111-8111-111111111111',
      const UpdateDroneStatusRequest(status: DroneStatus.available),
    );

    expect(updated.status, DroneStatus.available);
    expect(updated.maintenanceReason, isNull);
    expect(updated.maintenanceUntil, isNull);
  });

  test('mantenimiento sin motivo conserva el que ya tenía el dron', () async {
    final repo = _repo(
      drones: [
        _drone(
          status: DroneStatus.maintenance,
          reason: 'Cambio de hélices',
          until: '2026-10-15',
        ),
      ],
    );

    final updated = await repo.updateStatus(
      'd1111111-1111-4111-8111-111111111111',
      const UpdateDroneStatusRequest(
        status: DroneStatus.outOfService,
        estimatedEndDate: '2026-12-01',
      ),
    );

    expect(updated.status, DroneStatus.outOfService);
    expect(
      updated.maintenanceReason,
      'Cambio de hélices',
      reason: 'Nest conserva el motivo si no llega uno nuevo',
    );
    expect(updated.maintenanceUntil, '2026-12-01');
  });

  test('registrar mantenimiento deja el dron fuera de servicio', () async {
    final repo = _repo();

    final updated = await repo.registerMaintenance(
      'd1111111-1111-4111-8111-111111111111',
      const RegisterMaintenanceRequest(
        reason: '  Cambio de baterías  ',
        estimatedEndDate: '2026-11-30',
      ),
    );

    expect(updated.status, DroneStatus.outOfService);
    expect(updated.maintenanceReason, 'Cambio de baterías');
    expect(updated.maintenanceUntil, '2026-11-30');
  });

  test('un motivo en blanco no da 400: Nest solo exige que sea string', () async {
    final repo = _repo();

    final updated = await repo.registerMaintenance(
      'd1111111-1111-4111-8111-111111111111',
      const RegisterMaintenanceRequest(
        reason: '   ',
        estimatedEndDate: '2026-11-30',
      ),
    );

    expect(updated.status, DroneStatus.outOfService);
    expect(
      updated.maintenanceReason,
      '',
      reason: 'FleetService.registerMaintenance guarda reason.trim()',
    );
    expect(updated.maintenanceUntil, '2026-11-30');
  });

  test('una fecha que no sea AAAA-MM-DD responde 400', () async {
    final repo = _repo();

    await expectLater(
      repo.registerMaintenance(
        'd1111111-1111-4111-8111-111111111111',
        const RegisterMaintenanceRequest(
          reason: 'Revisión',
          estimatedEndDate: 'ayer',
        ),
      ),
      _message(400, 'La fecha estimada debe ser AAAA-MM-DD.'),
    );
    await expectLater(
      repo.updateStatus(
        'd1111111-1111-4111-8111-111111111111',
        const UpdateDroneStatusRequest(
          status: DroneStatus.maintenance,
          estimatedEndDate: '30/11/2026',
        ),
      ),
      _message(400, 'La fecha estimada debe ser AAAA-MM-DD.'),
    );
  });
}

/// Igual que `expectLater(..., throwsA(...))` con los dos atributos que
/// la UI lee de un `ApiException`.
Matcher _message(int statusCode, String message) {
  return throwsA(
    isA<ApiException>()
        .having((e) => e.statusCode, 'statusCode', statusCode)
        .having((e) => e.message, 'message', message),
  );
}
