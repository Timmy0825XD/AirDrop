import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/local/local_auth_repository.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';

class FakeTokenStore extends TokenStore {
  FakeTokenStore() : super();

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}

void main() {
  test('guarda la sesión al hacer login y la limpia al hacer logout', () async {
    final tokenStore = FakeTokenStore();
    final repository = LocalAuthRepository(tokenStore: tokenStore);
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokenStore),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(authControllerProvider.future);
    expect(initial.isAuthenticated, isFalse);

    await container
        .read(authControllerProvider.notifier)
        .login(
          LoginRequest(
            contact: AuthContact.email('demo@airdrop.local'),
            password: 'Demo1234',
          ),
        );

    expect(tokenStore.value, startsWith('local-session:'));
    expect(
      container.read(authControllerProvider).asData!.value.isAuthenticated,
      isTrue,
    );

    await container.read(authControllerProvider.notifier).logout();
    expect(tokenStore.value, isNull);
    expect(
      container.read(authControllerProvider).asData!.value.isAuthenticated,
      isFalse,
    );
  });

  test('restaura la sesión al abrir con un token válido', () async {
    final tokenStore = FakeTokenStore()
      ..value = 'local-session:11111111-1111-4111-8111-111111111111';
    final repository = LocalAuthRepository(tokenStore: tokenStore);
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokenStore),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(authControllerProvider.future);

    expect(state.isAuthenticated, isTrue);
    expect(state.user?.email, 'demo@airdrop.local');
  });
}
