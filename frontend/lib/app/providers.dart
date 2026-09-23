import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/token_store.dart';
import '../core/network/api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);
