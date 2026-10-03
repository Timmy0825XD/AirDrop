import '../../../../core/api_exception.dart';
import '../../../../core/auth/token_store.dart';
import '../../../../core/field_limits.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/local/local_auth_rules.dart';
import '../../auth/data/local/local_fixtures.dart';
import 'geofence_models.dart';
import 'geofence_repository.dart';

/// Geovallas simuladas en memoria, para trabajar sin NestJS. Replica los
/// mensajes y el orden de validaciones de `GeofencesService` para que los
/// dos orígenes de datos se comporten igual.
///
/// El orden es el de Nest: primero la sesión (`JwtStrategy.validate`
/// descarta las cuentas que no estén `active` con 401 **antes** de que el
/// servicio corra, así que el 403 de `assertActiveOperator` no se
/// alcanza, igual que en la flota), después las validaciones de los DTO y
/// por último las reglas del polígono.
class LocalGeofenceRepository implements GeofenceRepository {
  LocalGeofenceRepository({TokenStore? tokenStore, List<Geofence>? geofences})
    : _tokenStore = tokenStore ?? TokenStore(),
      // [geofences] permite arrancar con un estado concreto en las
      // pruebas. Las [Geofence] son inmutables.
      _geofences = List.of(geofences ?? _fixtures);

  final TokenStore _tokenStore;

  /// Copia por instancia: un borrado no se filtra entre sesiones de la
  /// maqueta.
  final List<Geofence> _geofences;

  /// Geovallas de partida de la maqueta, cerradas (primero == último).
  static final List<Geofence> _fixtures = [
    Geofence(
      id: 'e1111111-1111-4111-8111-111111111111',
      name: 'Corredor Aéreo Ambulancia',
      reason: 'Pasillo aéreo para traslados programados entre centrales',
      polygon: GeoJsonPolygon([
        [
          [-73.266, 10.442],
          [-73.266, 10.456],
          [-73.25, 10.456],
          [-73.25, 10.442],
          [-73.266, 10.442],
        ],
      ]),
      createdByUserId: '33333333-3333-4333-8333-333333333333',
      createdAt: DateTime.utc(2026, 9, 1, 12),
    ),
    Geofence(
      id: 'e2222222-2222-4222-8222-222222222222',
      name: 'Zona Restricción Hospital General',
      reason: 'Vertiginoso: sin vuelo a baja altura sobre el hospital',
      polygon: GeoJsonPolygon([
        [
          [-73.262, 10.455],
          [-73.244, 10.455],
          [-73.253, 10.472],
          [-73.262, 10.455],
        ],
      ]),
      createdByUserId: '33333333-3333-4333-8333-333333333333',
      createdAt: DateTime.utc(2026, 9, 2, 9),
    ),
  ];

  @override
  Future<List<Geofence>> list() async {
    await _requireActiveAccount();
    final rows = [..._geofences]..sort((a, b) => a.name.compareTo(b.name));
    return List<Geofence>.unmodifiable(rows);
  }

  @override
  Future<Geofence> create(CreateGeofenceRequest request) async {
    final user = await _requireActiveAccount();
    _assertDto(name: request.name, reason: request.reason);
    _assertPolygon(request.polygon);
    final geofence = Geofence(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: request.name.trim(),
      reason: request.reason.trim(),
      polygon: request.polygon,
      createdByUserId: user.id,
      createdAt: DateTime.now(),
    );
    _geofences.add(geofence);
    return geofence;
  }

  @override
  Future<Geofence> update(String id, UpdateGeofenceRequest request) async {
    await _requireActiveAccount();
    _assertDto(name: request.name, reason: request.reason);
    // La validación vive en el servicio y corre después de los DTO:
    // un PATCH sin campos responde 400 antes de buscar la geovalla.
    if (request.isEmpty) {
      throw const ApiException(
        'Debes enviar al menos un campo para actualizar.',
        statusCode: 400,
      );
    }
    final index = _indexOf(id);
    final polygon = request.polygon;
    if (polygon != null) _assertPolygon(polygon);
    final current = _geofences[index];
    final updated = Geofence(
      id: current.id,
      name: request.name?.trim() ?? current.name,
      reason: request.reason?.trim() ?? current.reason,
      polygon: polygon ?? current.polygon,
      createdByUserId: current.createdByUserId,
      createdAt: current.createdAt,
    );
    _geofences[index] = updated;
    return updated;
  }

  @override
  Future<void> remove(String id) async {
    await _requireActiveAccount();
    _geofences.removeAt(_indexOf(id));
  }

  /// Réplica de `CreateGeofenceDto` y `UpdateGeofenceDto`: Nest solo
  /// exige `@IsString` + `@MaxLength`, así que un nombre o motivo en
  /// blanco **no** da 400, se guarda con `trim()`. La app no llega acá
  /// con blancos porque el formulario los valida como obligatorios.
  void _assertDto({String? name, String? reason}) {
    if (name != null && name.length > FieldLimits.geofenceName) {
      throw ApiException(
        'El nombre no puede superar ${FieldLimits.geofenceName} caracteres.',
        statusCode: 400,
      );
    }
    if (reason != null && reason.length > FieldLimits.reason) {
      throw ApiException(
        'El motivo no puede superar ${FieldLimits.reason} caracteres.',
        statusCode: 400,
      );
    }
  }

  /// Réplica de `assertGeoJsonPolygon`. El `type` y `coordinates` ya
  /// validan los DTO y el modelo es tipado, así que acá empieza la regla
  /// del anillo, igual que en Nest.
  void _assertPolygon(GeoJsonPolygon polygon) {
    final ring = polygon.ring;
    if (ring.length < 4) {
      throw const ApiException(
        'El polígono necesita al menos 4 puntos y debe estar cerrado.',
        statusCode: 400,
      );
    }
    for (final point in ring) {
      final longitude = point[0];
      final latitude = point[1];
      if (longitude.isNaN ||
          latitude.isNaN ||
          longitude < -180 ||
          longitude > 180 ||
          latitude < -90 ||
          latitude > 90) {
        throw const ApiException(
          'Cada punto debe ser [longitud, latitud] con rangos válidos.',
          statusCode: 400,
        );
      }
    }
    final first = ring.first;
    final last = ring.last;
    if (first[0] != last[0] || first[1] != last[1]) {
      throw const ApiException(
        'El primer y el último punto del polígono deben coincidir.',
        statusCode: 400,
      );
    }
  }

  /// Réplica de `requireGeofence`: 404 con el mensaje de Nest.
  int _indexOf(String id) {
    final index = _geofences.indexWhere((geofence) => geofence.id == id);
    if (index < 0) {
      throw const ApiException('La geovalla no existe.', statusCode: 404);
    }
    return index;
  }

  /// Réplica de lo que ve el cliente: `JwtStrategy.validate` descarta las
  /// cuentas que no estén `active` con 401 antes de que el servicio
  /// corra, así que el 403 de `assertActiveOperator` no se alcanza.
  Future<_SessionUser> _requireActiveAccount() async {
    final user = await _sessionUser();
    if (user == null || user.status != UserStatus.active) {
      throw LocalAuthRules.expiredSession();
    }
    return user;
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
        return _SessionUser(id: user.id, status: user.status);
      }
    }
    return null;
  }
}

/// Alcance mínimo que `GeofencesService` mira de la sesión: id y estado.
class _SessionUser {
  const _SessionUser({required this.id, required this.status});

  final String id;
  final UserStatus status;
}
