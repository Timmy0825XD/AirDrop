import '../../../core/api_exception.dart';
import '../../../core/auth/token_store.dart';
import '../../auth/data/local/local_fixtures.dart';
import 'hub_models.dart';
import 'hub_repository.dart';

/// Lista simulada en memoria, para trabajar sin NestJS. Reproduce los
/// mensajes y el 409 de Nest para que el comportamiento sea el mismo.
class LocalHubRepository implements HubRepository {
  LocalHubRepository({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _hubs = [_demoHub];

  final TokenStore _tokenStore;

  /// La central simulada. Se copia por cada instancia para que suspenderla
  /// no se filtre entre sesiones de la maqueta.
  static final Hub _demoHub = Hub(
    id: localFixtureHubId,
    name: 'Central Demo',
    type: HubType.hospital,
    address: 'Calle 15 # 12-45, Valledupar, Cesar',
    latitude: 10.463140,
    longitude: -73.253220,
    contactPhone: '3001234567',
    contactEmail: 'central@airdrop.local',
    status: HubStatus.active,
    createdAt: DateTime.utc(2026, 9, 1, 12),
  );

  final List<Hub> _hubs;

  @override
  Future<Hub?> mine() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    return _hubs.firstWhere((hub) => hub.id == localFixtureHubId);
  }

  @override
  Future<List<Hub>> list({HubStatus? status}) async {
    final rows = status == null
        ? _hubs
        : _hubs.where((hub) => hub.status == status).toList(growable: false);
    return List<Hub>.unmodifiable(rows);
  }

  @override
  Future<Hub> create(CreateHubRequest request) async {
    final hub = Hub(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: request.name.trim(),
      type: request.type,
      address: request.address.trim(),
      latitude: request.latitude,
      longitude: request.longitude,
      contactPhone: request.contactPhone,
      contactEmail: request.contactEmail,
      status: HubStatus.active,
      createdAt: DateTime.now(),
    );
    _hubs.insert(0, hub);
    return hub;
  }

  /// Aplica los cambios como Nest: sin campos responde 400.
  @override
  Future<Hub> update(String id, Map<String, dynamic> changes) async {
    final index = _hubs.indexWhere((hub) => hub.id == id);
    if (index < 0) {
      throw ApiException('La central no existe.', statusCode: 404);
    }
    if (changes.isEmpty) {
      throw ApiException(
        'Debes enviar al menos un campo para actualizar.',
        statusCode: 400,
      );
    }
    final current = _hubs[index];
    final type = changes['type'];
    _hubs[index] = Hub(
      id: current.id,
      name: changes['name'] as String? ?? current.name,
      type: type is String ? HubType.fromJson(type) : current.type,
      address: changes['address'] as String? ?? current.address,
      latitude: (changes['latitude'] as num?)?.toDouble() ?? current.latitude,
      longitude:
          (changes['longitude'] as num?)?.toDouble() ?? current.longitude,
      contactPhone: changes['contactPhone'] as String? ?? current.contactPhone,
      contactEmail: changes.containsKey('contactEmail')
          ? changes['contactEmail'] as String?
          : current.contactEmail,
      status: current.status,
      createdAt: current.createdAt,
    );
    return _hubs[index];
  }

  @override
  Future<Hub> setSuspension(String id, {required bool suspended}) async {
    final index = _hubs.indexWhere((hub) => hub.id == id);
    if (index < 0) {
      throw ApiException('La central no existe.', statusCode: 404);
    }
    final current = _hubs[index];
    final next = suspended ? HubStatus.suspended : HubStatus.active;
    if (current.status == next) {
      throw ApiException(
        suspended
            ? 'Esta central ya está suspendida.'
            : 'Esta central ya está activa.',
        statusCode: 409,
      );
    }
    final updated = Hub(
      id: current.id,
      name: current.name,
      type: current.type,
      address: current.address,
      latitude: current.latitude,
      longitude: current.longitude,
      contactPhone: current.contactPhone,
      contactEmail: current.contactEmail,
      status: next,
      createdAt: current.createdAt,
    );
    _hubs[index] = updated;
    return updated;
  }
}
