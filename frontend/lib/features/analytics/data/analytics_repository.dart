import 'analytics_models.dart';

/// Contrato de las métricas; las tres rutas son solo del administrador.
abstract class AnalyticsRepository {
  /// `GET /analytics/kpis?from&to&hubId?`.
  Future<KpiReport> kpis(AnalyticsQuery query);

  /// `GET /analytics/demand?from&to&hubId?`.
  Future<DemandReport> demand(AnalyticsQuery query);

  /// `GET /analytics/hubs?from&to` (sin central: compara todas).
  Future<List<HubRanking>> hubs(AnalyticsQuery query);
}
