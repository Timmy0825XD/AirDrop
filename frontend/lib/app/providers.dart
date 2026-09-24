import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/token_store.dart';
import '../core/data/data_source.dart';
import '../core/data/data_source_config.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/local/local_auth_repository.dart';
import '../features/auth/data/remote/remote_auth_repository.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return switch (appDataSource) {
    DataSource.local => LocalAuthRepository(tokenStore: tokenStore),
    DataSource.remote => RemoteAuthRepository(apiClient: apiClient),
  };
});
