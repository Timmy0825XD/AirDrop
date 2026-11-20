import 'dart:math' as math;

import '../../../core/api_exception.dart';
import '../../../core/auth/token_store.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/local/local_auth_rules.dart';
import '../../auth/data/local/local_fixtures.dart';
import 'geofence_models.dart';
import 'geofence_repository.dart';

/// Geovallas en memoria, para trabajar sin NestJS. Replica los mensajes de
/// `GeofencesService`, `LegalZonesService` y `geofence-shape.rules.ts`.
class LocalGeofenceRepository implements GeofenceRepository {
  LocalGeofenceRepository({TokenStore? tokenStore, List<Geofence>? geofences})
    : _tokenStore = tokenStore ?? TokenStore(),
      _geofences = List.of(geofences ?? localGeofenceFixtures);

  final TokenStore _tokenStore;
  final List<Geofence> _geofences;
  final Map<String, List<GeofenceChange>> _changes = {};

  @override
  Future<List<Geofence>> list() async {
    await _session();
    final rows = _geofences.where((g) => !g.isTemporary).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(rows);
  }

  @override
  Future<List<GeofenceChange>> changes(String id) async {
    await _session();
    _legal(id);
    return List.unmodifiable(_changes[id] ?? const []);
  }

  @override
  Future<Geofence> create(CreateGeofenceRequest request) async {
    final userId = await _session();
    return _add(
      Geofence(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        geofenceClass: GeofenceClass.operational,
        shape: request.geometry.shape,
        name: request.name.trim(),
        reason: request.reason.trim(),
        category: request.category,
        center: request.geometry.center,
        radiusM: request.geometry.radiusM,
        polygon: localPolygonOf(request.geometry),
        createdByUserId: userId,
        createdAt: DateTime.now(),
        expiresAt: request.expiresAt,
      ),
    );
  }

  @override
  Future<Geofence> update(String id, UpdateGeofenceRequest request) async {
    final userId = await _session();
    if (request.isEmpty) throw _noChanges;
    final index = _index(id, (g) => g.isOperational);
    final current = _geofences[index];
    final geometry = request.geometry;
    final updated = _copy(
      current,
      name: request.name,
      reason: request.reason,
      category: request.category,
      geometry: geometry,
      updatedByUserId: userId,
      expiresAt: request.clearExpiry
          ? null
          : request.expiresAt ?? current.expiresAt,
    );
    return _geofences[index] = updated;
  }

  @override
  Future<void> remove(String id) async {
    await _session();
    _geofences.removeAt(_index(id, (g) => g.isOperational));
  }

  @override
  Future<Geofence> createLegal(CreateLegalZoneRequest request) async {
    final userId = await _session();
    if (_geofences.any((g) => g.code == request.code)) {
      throw const ApiException(
        'Ya existe una zona legal con ese código.',
        statusCode: 409,
      );
    }
    final zone = _add(
      Geofence(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        geofenceClass: request.geofenceClass,
        shape: request.geometry.shape,
        name: request.name,
        center: request.geometry.center,
        radiusM: request.geometry.radiusM,
        polygon: localPolygonOf(request.geometry),
        code: request.code,
        legalBasis: request.legalBasis,
        source: request.source,
        createdByUserId: userId,
        createdAt: DateTime.now(),
      ),
    );
    _record(zone.id, GeofenceChangeAction.created, null, const []);
    return zone;
  }

  @override
  Future<Geofence> updateLegal(
    String id,
    UpdateLegalZoneRequest request,
  ) async {
    final userId = await _session();
    if (!request.hasChanges) throw _noChanges;
    final index = _legal(id);
    final current = _geofences[index];
    final updated = _copy(
      current,
      geofenceClass: request.geofenceClass,
      name: request.name,
      legalBasis: request.legalBasis,
      source: request.source,
      geometry: request.geometry,
      updatedByUserId: userId,
    );
    _record(id, GeofenceChangeAction.updated, request.reason, [
      for (final key in request.toJson().keys)
        if (key != 'reason') key,
    ]);
    return _geofences[index] = updated;
  }

  @override
  Future<Geofence> setLegalActive(
    String id, {
    required bool active,
    required String reason,
  }) async {
    final userId = await _session();
    final index = _legal(id);
    final current = _geofences[index];
    if (current.active == active) {
      throw ApiException(
        active
            ? 'La zona legal ya está activa.'
            : 'La zona legal ya está desactivada.',
        statusCode: 409,
      );
    }
    _record(
      id,
      active
          ? GeofenceChangeAction.reactivated
          : GeofenceChangeAction.deactivated,
      reason,
      const ['active'],
    );
    return _geofences[index] = _copy(
      current,
      active: active,
      updatedByUserId: userId,
    );
  }

  static const _noChanges = ApiException(
    'Debes enviar al menos un campo para actualizar.',
    statusCode: 400,
  );

  Geofence _add(Geofence geofence) {
    _geofences.add(geofence);
    return geofence;
  }

  void _record(
    String id,
    GeofenceChangeAction action,
    String? reason,
    List<String> fields,
  ) {
    (_changes[id] ??= []).insert(
      0,
      GeofenceChange(
        id: 'change-${DateTime.now().microsecondsSinceEpoch}',
        action: action,
        reason: reason,
        fields: fields,
        createdAt: DateTime.now(),
      ),
    );
  }

  int _legal(String id) {
    final index = _geofences.indexWhere((g) => g.id == id && g.isLegal);
    if (index < 0) {
      throw const ApiException('La zona legal no existe.', statusCode: 404);
    }
    return index;
  }

  int _index(String id, bool Function(Geofence) test) {
    final index = _geofences.indexWhere((g) => g.id == id && test(g));
    if (index < 0) {
      throw const ApiException('La geovalla no existe.', statusCode: 404);
    }
    return index;
  }

  /// La cuenta de la sesión simulada; 401 si no está activa.
  Future<String> _session() async {
    final token = await _tokenStore.read();
    if (token != null && token.startsWith(LocalAuthRules.tokenPrefix)) {
      final id = token.substring(LocalAuthRules.tokenPrefix.length);
      for (final user in localFixtureUsers) {
        if (user.id == id && user.status == UserStatus.active) return user.id;
      }
    }
    throw LocalAuthRules.expiredSession();
  }
}

Geofence _copy(
  Geofence current, {
  GeofenceClass? geofenceClass,
  String? name,
  String? reason,
  OperationalCategory? category,
  GeofenceGeometry? geometry,
  String? legalBasis,
  String? source,
  bool? active,
  String? updatedByUserId,
  DateTime? expiresAt,
}) {
  return Geofence(
    id: current.id,
    geofenceClass: geofenceClass ?? current.geofenceClass,
    shape: geometry?.shape ?? current.shape,
    name: name?.trim() ?? current.name,
    reason: reason?.trim() ?? current.reason,
    category: category ?? current.category,
    center: geometry != null ? geometry.center : current.center,
    radiusM: geometry != null ? geometry.radiusM : current.radiusM,
    polygon: geometry != null ? localPolygonOf(geometry) : current.polygon,
    code: current.code,
    legalBasis: legalBasis ?? current.legalBasis,
    source: source ?? current.source,
    active: active ?? current.active,
    createdByUserId: current.createdByUserId,
    updatedByUserId: updatedByUserId ?? current.updatedByUserId,
    createdAt: current.createdAt,
    updatedAt: DateTime.now(),
    expiresAt: expiresAt ?? current.expiresAt,
  );
}

/// El polígono de una geometría: un círculo de 16 lados o los vértices
/// cerrados, como lo arma Nest.
GeoJsonPolygon localPolygonOf(GeofenceGeometry geometry) {
  if (geometry.shape == GeofenceShape.polygon) {
    final ring = [for (final p in geometry.vertices) p.toLngLat()];
    if (ring.isNotEmpty) ring.add(ring.first);
    return GeoJsonPolygon([ring]);
  }
  final center = geometry.center!;
  final radiusDeg = geometry.radiusM! / 111320;
  final ring = [
    for (var i = 0; i <= 16; i++)
      [
        center.longitude +
            radiusDeg *
                math.cos(2 * math.pi * i / 16) /
                math.cos(center.latitude * math.pi / 180),
        center.latitude + radiusDeg * math.sin(2 * math.pi * i / 16),
      ],
  ];
  return GeoJsonPolygon([ring]);
}

/// Una operativa y dos zonas legales de la demo.
final List<Geofence> localGeofenceFixtures = [
  Geofence(
    id: 'e1111111-1111-4111-8111-111111111111',
    geofenceClass: GeofenceClass.operational,
    shape: GeofenceShape.polygon,
    name: 'Fumigación aérea de cultivos',
    reason: 'Avioneta fumigando entre Valencia de Jesús y Mariangola',
    category: OperationalCategory.other,
    polygon: const GeoJsonPolygon([
      [
        [-73.49, 10.244],
        [-73.47, 10.244],
        [-73.468, 10.262],
        [-73.49, 10.262],
        [-73.49, 10.244],
      ],
    ]),
    createdByUserId: '33333333-3333-4333-8333-333333333333',
    createdAt: DateTime.utc(2026, 9, 1, 12),
  ),
  for (final (id, cls, code, name, lat, lng, radius) in const [
    (
      'e2222222-2222-4222-8222-222222222222',
      GeofenceClass.aerodrome,
      'skvp',
      'Aeropuerto Alfonso López Pumarejo (SKVP)',
      10.43513,
      -73.2494,
      1500,
    ),
    (
      'e3333333-3333-4333-8333-333333333333',
      GeofenceClass.prohibited,
      'cai-gobernacion',
      'CAI Gobernación',
      10.4762,
      -73.2465,
      100,
    ),
  ])
    Geofence(
      id: id,
      geofenceClass: cls,
      shape: GeofenceShape.circle,
      name: name,
      center: GeoPoint(latitude: lat, longitude: lng),
      radiusM: radius,
      polygon: localPolygonOf(
        GeofenceGeometry.circle(
          center: GeoPoint(latitude: lat, longitude: lng),
          radiusM: radius,
        ),
      ),
      code: code,
      legalBasis: 'RAC 100.315(a): tamaño del visor de la Aerocivil (demo)',
      source: 'Equipo AirDrop',
    ),
];
