import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import 'hub_models.dart';
import 'hub_repository.dart';
import 'local_hub_repository.dart';
import 'remote_hub_repository.dart';

final hubRepositoryProvider = Provider<HubRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return switch (appDataSource) {
    DataSource.local => LocalHubRepository(tokenStore: tokenStore),
    DataSource.remote => RemoteHubRepository(apiClient: apiClient),
  };
});

final myHubProvider = FutureProvider<HubSummary?>((ref) {
  return ref.watch(hubRepositoryProvider).mine();
});
