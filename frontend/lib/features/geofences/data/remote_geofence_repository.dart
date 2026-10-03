import '../../../../core/api_exception.dart';
import '../../../../core/network/api_client.dart';
import 'geofence_models.dart';
import 'geofence_repository.dart';

/// Las cuatro operaciones contra Nest (`GeofencesController`, solo
/// `fleet_operator`). Todos los errores se relanzan como [ApiException]
/// para que la UI muestre el mensaje que define el backend.
class RemoteGeofenceRepository implements GeofenceRepository {
  RemoteGeofenceRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<Geofence>> list() async {
    final data = await apiClient.getJson('/geofences');
    return _asJsonList(
      data,
    ).map((row) => Geofence.fromJson(_asJsonMap(row))).toList(growable: false);
  }

  @override
  Future<Geofence> create(CreateGeofenceRequest request) async {
    final data = await apiClient.postJson('/geofences', body: request.toJson());
    return Geofence.fromJson(_asJsonMap(data));
  }

  @override
  Future<Geofence> update(String id, UpdateGeofenceRequest request) async {
    final data = await apiClient.patchJson(
      '/geofences/$id',
      body: request.toJson(),
    );
    return Geofence.fromJson(_asJsonMap(data));
  }

  @override
  Future<void> remove(String id) => apiClient.delete('/geofences/$id');

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La geovalla no es un objeto JSON.');
  }

  List<Object?> _asJsonList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException('La respuesta de geovallas no es una lista.');
  }
}
