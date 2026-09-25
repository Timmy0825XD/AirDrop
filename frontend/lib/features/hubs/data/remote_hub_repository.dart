import '../../../../core/api_exception.dart';
import '../../../../core/network/api_client.dart';
import 'hub_models.dart';
import 'hub_repository.dart';

class RemoteHubRepository implements HubRepository {
  RemoteHubRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<HubSummary?> mine() async {
    try {
      final data = await apiClient.getJson('/hubs/me');
      return HubSummary.fromJson(_asJsonMap(data));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException(
      'La respuesta de la central no es un objeto JSON.',
    );
  }
}
