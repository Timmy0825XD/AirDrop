import '../../../core/network/api_client.dart';
import 'analytics_models.dart';
import 'analytics_repository.dart';

/// Las métricas contra Nest. No captura el error: `ApiClient` ya lanza
/// `ApiException` con el mensaje del servidor.
class RemoteAnalyticsRepository implements AnalyticsRepository {
  RemoteAnalyticsRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<KpiReport> kpis(AnalyticsQuery query) async =>
      KpiReport.fromJson(await _get('/analytics/kpis', query.toQuery()));

  @override
  Future<DemandReport> demand(AnalyticsQuery query) async =>
      DemandReport.fromJson(await _get('/analytics/demand', query.toQuery()));

  @override
  Future<List<HubRanking>> hubs(AnalyticsQuery query) async =>
      HubRanking.listFromJson(
        await _get('/analytics/hubs', query.toQuery(withHub: false)),
      );

  Future<Map<String, dynamic>> _get(String path, Map<String, String> q) async {
    final data = await apiClient.getJson(path, query: q);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('La respuesta de métricas no es un objeto.');
  }
}
