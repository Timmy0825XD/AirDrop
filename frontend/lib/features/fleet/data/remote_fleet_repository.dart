import '../../../../core/network/api_client.dart';
import 'fleet_models.dart';
import 'fleet_repository.dart';

/// Las cinco operaciones contra Nest (`FleetController`, solo
/// `fleet_operator`). Todos los errores se relanzan como [ApiException]
/// para que la UI muestre el mensaje que define el backend.
class RemoteFleetRepository implements FleetRepository {
  RemoteFleetRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<DroneModel>> listModels() async {
    final data = await apiClient.getJson('/fleet/models');
    return _asJsonList(data)
        .map((row) => DroneModel.fromJson(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<List<Drone>> listDrones(String hubId) async {
    final data = await apiClient.getJson(
      '/fleet/drones',
      query: {'hubId': hubId},
    );
    return _asJsonList(data)
        .map((row) => Drone.fromJson(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<Drone> create(CreateDroneRequest request) async {
    final data = await apiClient.postJson(
      '/fleet/drones',
      body: request.toJson(),
    );
    return Drone.fromJson(_asJsonMap(data));
  }

  @override
  Future<Drone> updateStatus(
    String id,
    UpdateDroneStatusRequest request,
  ) async {
    final data = await apiClient.patchJson(
      '/fleet/drones/$id/status',
      body: request.toJson(),
    );
    return Drone.fromJson(_asJsonMap(data));
  }

  @override
  Future<Drone> registerMaintenance(
    String id,
    RegisterMaintenanceRequest request,
  ) async {
    final data = await apiClient.postJson(
      '/fleet/drones/$id/maintenance',
      body: request.toJson(),
    );
    return Drone.fromJson(_asJsonMap(data));
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La respuesta del dron no es un objeto JSON.');
  }

  List<Object?> _asJsonList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException('La respuesta no es una lista JSON.');
  }
}
