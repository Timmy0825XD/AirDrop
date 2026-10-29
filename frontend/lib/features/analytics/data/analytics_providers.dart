import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../auth/presentation/auth_controller.dart';
import 'analytics_models.dart';
import 'analytics_repository.dart';
import 'local_analytics_repository.dart';
import 'remote_analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  // Otra cuenta, otro repositorio: lo cargado por la anterior se descarta.
  ref.watch(sessionUserIdProvider);
  return switch (appDataSource) {
    DataSource.local => LocalAnalyticsRepository(),
    DataSource.remote => RemoteAnalyticsRepository(
      apiClient: ref.watch(apiClientProvider),
    ),
  };
});

final kpisProvider = FutureProvider.family<KpiReport, AnalyticsQuery>((
  ref,
  query,
) {
  return ref.watch(analyticsRepositoryProvider).kpis(query);
});

final demandProvider = FutureProvider.family<DemandReport, AnalyticsQuery>((
  ref,
  query,
) {
  return ref.watch(analyticsRepositoryProvider).demand(query);
});

final hubRankingProvider =
    FutureProvider.family<List<HubRanking>, AnalyticsQuery>((ref, query) {
      return ref.watch(analyticsRepositoryProvider).hubs(query);
    });
