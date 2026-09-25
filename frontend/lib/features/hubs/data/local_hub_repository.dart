import '../../../../core/auth/token_store.dart';
import 'hub_models.dart';
import 'hub_repository.dart';

class LocalHubRepository implements HubRepository {
  LocalHubRepository({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore();

  final TokenStore _tokenStore;

  @override
  Future<HubSummary?> mine() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;

    return const HubSummary(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      name: 'Central Demo',
      status: HubStatus.approved,
    );
  }
}
