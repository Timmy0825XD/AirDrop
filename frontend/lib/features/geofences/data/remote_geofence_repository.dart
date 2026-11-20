import '../../../core/network/api_client.dart';
import 'geofence_models.dart';
import 'geofence_repository.dart';

/// Las geovallas contra Nest (`GeofencesController` y
/// `LegalZonesController`). Los errores llegan como `ApiException` para que
/// la UI muestre el mensaje que define el backend.
class RemoteGeofenceRepository implements GeofenceRepository {
  RemoteGeofenceRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<Geofence>> list() async {
    final data = await apiClient.getJson('/geofences');
    return [for (final row in _asList(data)) Geofence.fromJson(_asMap(row))];
  }

  @override
  Future<List<GeofenceChange>> changes(String id) async {
    final data = await apiClient.getJson('/geofences/$id/changes');
    return [
      for (final row in _asList(data)) GeofenceChange.fromJson(_asMap(row)),
    ];
  }

  @override
  Future<Geofence> create(CreateGeofenceRequest request) =>
      _one(apiClient.postJson('/geofences', body: request.toJson()));

  @override
  Future<Geofence> update(String id, UpdateGeofenceRequest request) =>
      _one(apiClient.patchJson('/geofences/$id', body: request.toJson()));

  @override
  Future<void> remove(String id) => apiClient.delete('/geofences/$id');

  @override
  Future<Geofence> createLegal(CreateLegalZoneRequest request) =>
      _one(apiClient.postJson('/geofences/legal', body: request.toJson()));

  @override
  Future<Geofence> updateLegal(String id, UpdateLegalZoneRequest request) =>
      _one(apiClient.patchJson('/geofences/legal/$id', body: request.toJson()));

  @override
  Future<Geofence> setLegalActive(
    String id, {
    required bool active,
    required String reason,
  }) => _one(
    apiClient.postJson(
      '/geofences/legal/$id/${active ? 'reactivate' : 'deactivate'}',
      body: {'reason': reason},
    ),
  );

  Future<Geofence> _one(Future<dynamic> call) async =>
      Geofence.fromJson(_asMap(await call));

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La geovalla no es un objeto JSON.');
  }

  List<Object?> _asList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException('La respuesta de geovallas no es una lista.');
  }
}
