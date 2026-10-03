import '../../../../core/api_exception.dart';
import '../../../../core/network/api_client.dart';
import 'hub_models.dart';
import 'hub_repository.dart';

/// Las cuatro operaciones contra Nest. Solo [mine] traduce un 404 en
/// `null`: para el despachador "sin central asignada" es un caso normal,
/// no un error. El resto relanza el [ApiException] para que la UI muestre
/// el mensaje que define el backend.
class RemoteHubRepository implements HubRepository {
  RemoteHubRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<Hub?> mine() async {
    try {
      final data = await apiClient.getJson('/hubs/me');
      return Hub.fromJson(_asJsonMap(data));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Hub>> list({HubStatus? status}) async {
    final data = await apiClient.getJson(
      '/hubs',
      query: {if (status != null) 'status': status.apiValue},
    );
    return _asJsonList(data)
        .map((row) => Hub.fromJson(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<Hub> create(CreateHubRequest request) async {
    final data = await apiClient.postJson('/hubs', body: request.toJson());
    return Hub.fromJson(_asJsonMap(data));
  }

  @override
  Future<Hub> setSuspension(String id, {required bool suspended}) async {
    final data = await apiClient.patchJson(
      '/hubs/$id/suspension',
      body: {'suspended': suspended},
    );
    return Hub.fromJson(_asJsonMap(data));
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La respuesta de la central no es un objeto JSON.');
  }

  List<Object?> _asJsonList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException('La respuesta de las centrales no es una lista JSON.');
  }
}
