import '../../../../core/api_exception.dart';
import '../../../../core/auth/token_store.dart';
import '../../../../core/field_limits.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/local/local_auth_rules.dart';
import '../../auth/data/local/local_fixtures.dart';
import '../../hubs/data/hub_repository.dart';
import 'fleet_models.dart';
import 'fleet_repository.dart';

/// Id del modelo de dron de la maqueta, para que los fixtures locales y
/// los tests apunten al mismo modelo que siembra Nest (`WINGCOPTER_198`).
const String localFixtureDroneModelId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

/// Flota simulada en memoria, para trabajar sin NestJS. Replica los
/// mensajes y el 409 de `FleetService` para que el comportamiento sea el
/// mismo en los dos orígenes de datos.
///
/// El orden de las validaciones es el de Nest: primero la cuenta activa,
/// luego la central, después la asignación y por último el estado del
/// dron. Una central **suspendida** sigue listando y cambiando sus drones:
/// solo el alta la bloquea (`HubsService.requireActive`), igual que en Nest.
class LocalFleetRepository implements FleetRepository {
  LocalFleetRepository({
    required this.hubRepository,
    TokenStore? tokenStore,
    List<Drone>? drones,
  }) : _tokenStore = tokenStore ?? TokenStore(),
       // [drones] permite arrancar con un estado concreto en las pruebas
       // (p. ej. un dron en misión), que la UI nunca produce por sí sola.
       _drones = List.of(drones ?? _fixtures);

  final HubRepository hubRepository;
  final TokenStore _tokenStore;

  /// Copia por instancia: cambiar un estado no se filtra entre sesiones de
  /// la maqueta. Las [Drone] son inmutables.
  final List<Drone> _drones;

  /// Drones de partida de la maqueta, en la central de demostración.
  static final List<Drone> _fixtures = [
    Drone(
      id: 'd1111111-1111-4111-8111-111111111111',
      identifier: 'DRON-01',
      droneModelId: localFixtureDroneModelId,
      hubId: localFixtureHubId,
      status: DroneStatus.available,
      createdAt: DateTime.utc(2026, 9, 1, 12),
    ),
    Drone(
      id: 'd2222222-2222-4222-8222-222222222222',
      identifier: 'DRON-02',
      droneModelId: localFixtureDroneModelId,
      hubId: localFixtureHubId,
      status: DroneStatus.maintenance,
      maintenanceReason: 'Cambio de hélices programado',
      maintenanceUntil: '2026-10-15',
      createdAt: DateTime.utc(2026, 9, 1, 12),
    ),
  ];

  @override
  Future<List<DroneModel>> listModels() async {
    return List<DroneModel>.unmodifiable(_models);
  }

  @override
  Future<List<Drone>> listDrones(String hubId) async {
    final user = await _requireActiveAccount();
    _assertAssigned(user, hubId);
    // `FleetService.listDrones` exige que la central exista, pero no que
    // esté activa: el operador puede revisar la flota de una central
    // suspendida.
    await _requireExistingHub(hubId);
    final rows = _drones.where((drone) => drone.hubId == hubId).toList()
      ..sort((a, b) => a.identifier.compareTo(b.identifier));
    return List<Drone>.unmodifiable(rows);
  }

  @override
  Future<Drone> create(CreateDroneRequest request) async {
    final user = await _requireActiveAccount();
    if (!_models.any((model) => model.id == request.droneModelId)) {
      throw const ApiException(
        'El modelo de dron no existe.',
        statusCode: 404,
      );
    }
    await _requireActiveHub(request.hubId);
    _assertAssigned(user, request.hubId);
    if (_drones.any((drone) => drone.identifier == request.identifier.trim())) {
      throw const ApiException(
        'Ya existe un dron con este identificador.',
        statusCode: 409,
      );
    }
    final drone = Drone(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      identifier: request.identifier.trim(),
      droneModelId: request.droneModelId,
      hubId: request.hubId,
      status: DroneStatus.available,
      createdAt: DateTime.now(),
    );
    _drones.add(drone);
    return drone;
  }

  @override
  Future<Drone> updateStatus(
    String id,
    UpdateDroneStatusRequest request,
  ) async {
    if (!DroneStatus.operatorStatuses.contains(request.status)) {
      throw const ApiException(
        'El estado debe ser available, maintenance o out_of_service.',
        statusCode: 400,
      );
    }
    _requireDto(request.reason, request.estimatedEndDate);
    final index = await _ownDroneIndex(id);
    final current = _drones[index];
    final reason = request.reason?.trim();
    final endDate = request.estimatedEndDate;

    // Igual que `FleetService.updateStatus`: `available` limpia motivo y
    // fecha; cualquier otro estado conserva los que ya tenía si no llegan.
    _drones[index] = Drone(
      id: current.id,
      identifier: current.identifier,
      droneModelId: current.droneModelId,
      hubId: current.hubId,
      status: request.status,
      maintenanceReason: request.status == DroneStatus.available
          ? null
          : (reason == null || reason.isEmpty
                ? current.maintenanceReason
                : reason),
      maintenanceUntil: request.status == DroneStatus.available
          ? null
          : ((endDate == null || endDate.isEmpty)
                ? current.maintenanceUntil
                : endDate),
      createdAt: current.createdAt,
    );
    return _drones[index];
  }

  @override
  Future<Drone> registerMaintenance(
    String id,
    RegisterMaintenanceRequest request,
  ) async {
    // Igual que `FleetService.registerMaintenance`: Nest solo exige que el
    // motivo sea string (`@IsString`) y lo guarda con `trim()`, así que un
    // motivo en blanco no produce 400 sino un dron con motivo vacío. La app
    // no puede llegar acá: el formulario lo valida como obligatorio.
    final reason = request.reason.trim();
    _requireDto(request.reason, request.estimatedEndDate);
    final index = await _ownDroneIndex(id);
    final current = _drones[index];
    _drones[index] = Drone(
      id: current.id,
      identifier: current.identifier,
      droneModelId: current.droneModelId,
      hubId: current.hubId,
      status: DroneStatus.outOfService,
      maintenanceReason: reason,
      maintenanceUntil: request.estimatedEndDate,
      createdAt: current.createdAt,
    );
    return _drones[index];
  }

  /// Réplica de las validaciones de `UpdateDroneStatusDto` y
  /// `RegisterMaintenanceDto`: Nest rechaza el motivo sobre 160 y la fecha
  /// que no sea `AAAA-MM-DD` **antes** de tocar el dron.
  void _requireDto(String? reason, String? endDate) {
    if (reason != null && reason.length > FieldLimits.reason) {
      throw ApiException(
        'El motivo no puede superar ${FieldLimits.reason} caracteres.',
        statusCode: 400,
      );
    }
    if (endDate != null && !FieldLimits.isoDateRegex.hasMatch(endDate)) {
      throw const ApiException(
        'La fecha estimada debe ser AAAA-MM-DD.',
        statusCode: 400,
      );
    }
  }

  /// Réplica de lo que ve el cliente: `JwtStrategy.validate` descarta
  /// cuentas que no estén `active` **antes** de que `FleetService` corra,
  /// así que Nest responde `401` (y `ApiClient` borra el token), no el
  /// `403` del `assertActiveOperator`, que en la práctica no se alcanza.
  Future<_SessionUser> _requireActiveAccount() async {
    final user = await _sessionUser();
    if (user == null || user.status != UserStatus.active) {
      throw LocalAuthRules.expiredSession();
    }
    return user;
  }

  /// Réplica de `assertAssigned`: la central debe estar en `hubIds`.
  void _assertAssigned(_SessionUser user, String hubId) {
    if (!user.hubIds.contains(hubId)) {
      throw const ApiException(
        'Esa central no está asignada a tu cuenta.',
        statusCode: 403,
      );
    }
  }

  /// Réplica de `HubsService.findById` dentro de `listDrones`.
  Future<void> _requireExistingHub(String hubId) async {
    final hubs = await hubRepository.list();
    for (final hub in hubs) {
      if (hub.id == hubId) return;
    }
    throw const ApiException('La central no existe.', statusCode: 404);
  }

  /// Réplica de `HubsService.requireActive`: existe y no está suspendida.
  Future<void> _requireActiveHub(String hubId) async {
    final hubs = await hubRepository.list();
    for (final hub in hubs) {
      if (hub.id != hubId) continue;
      if (!hub.isActive) {
        throw const ApiException(
          'La central está suspendida.',
          statusCode: 403,
        );
      }
      return;
    }
    throw const ApiException('La central no existe.', statusCode: 404);
  }

  /// Réplica de `requireActiveOperatorDrone` + `assertNotInMission`.
  Future<int> _ownDroneIndex(String id) async {
    final user = await _requireActiveAccount();
    final index = _drones.indexWhere((drone) => drone.id == id);
    if (index < 0) {
      throw const ApiException('El dron no existe.', statusCode: 404);
    }
    _assertAssigned(user, _drones[index].hubId);
    if (_drones[index].status.isInMission) {
      throw const ApiException(
        'No puedes cambiar el estado de un dron en misión.',
        statusCode: 409,
      );
    }
    return index;
  }

  /// Cuenta de la sesión simulada: el token local es
  /// `local-session:<id>` (ver `LocalAuthRules.tokenPrefix`).
  Future<_SessionUser?> _sessionUser() async {
    final token = await _tokenStore.read();
    if (token == null || !token.startsWith(LocalAuthRules.tokenPrefix)) {
      return null;
    }
    final id = token.substring(LocalAuthRules.tokenPrefix.length);
    for (final user in localFixtureUsers) {
      if (user.id == id) {
        return _SessionUser(status: user.status, hubIds: user.hubIds);
      }
    }
    return null;
  }

  /// Modelos de la maqueta: los mismos que siembra Nest.
  static final List<DroneModel> _models = [
    const DroneModel(
      id: localFixtureDroneModelId,
      code: 'wingcopter_198',
      name: 'Wingcopter 198',
      maxSpeedKmh: 150,
      maxPayloadKg: 6,
      maxRangeKm: 110,
    ),
  ];
}

/// Alcance mínimo que `FleetService` mira de la sesión: estado y centrales.
class _SessionUser {
  const _SessionUser({required this.status, required this.hubIds});

  final UserStatus status;
  final List<String> hubIds;
}
