import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
import 'local_user_repository.dart';
import 'remote_user_repository.dart';
import 'user_models.dart';
import 'user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return switch (appDataSource) {
    DataSource.local => LocalUserRepository(tokenStore: tokenStore),
    DataSource.remote => RemoteUserRepository(apiClient: apiClient),
  };
});

/// Filtro de rol del listado: `null` es "Todos". `GET /users?role=` sin
/// parámetro devuelve los dos roles institucionales.
class UserRoleFilterNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;

  void select(UserRole? role) => state = role;
}

final userRoleFilterProvider =
    NotifierProvider<UserRoleFilterNotifier, UserRole?>(
      UserRoleFilterNotifier.new,
    );

/// Filtro de estado del listado: `null` es "Todos".
class UserStatusFilterNotifier extends Notifier<UserStatus?> {
  @override
  UserStatus? build() => null;

  void select(UserStatus? status) => state = status;
}

final userStatusFilterProvider =
    NotifierProvider<UserStatusFilterNotifier, UserStatus?>(
      UserStatusFilterNotifier.new,
    );

/// Listado de cuentas institucionales. Sigue a los dos filtros, así que un
/// solo `invalidate` de este provider refresca lo que se ve en pantalla.
final usersProvider = FutureProvider<List<PublicUser>>((ref) {
  final role = ref.watch(userRoleFilterProvider);
  final status = ref.watch(userStatusFilterProvider);
  return ref.watch(userRepositoryProvider).list(role: role, status: status);
});

/// Centrales que el formulario de cuentas puede ofrecer: solo las
/// `active`, porque Nest rechaza cualquier otra con
/// "Solo puedes asignar centrales activas.". Lee el repositorio de `hubs`
/// directamente, sin pasar por el filtro del listado de esa pantalla.
final assignableHubsProvider = FutureProvider<List<Hub>>((ref) {
  return ref.watch(hubRepositoryProvider).list(status: HubStatus.active);
});

/// Alta de cuenta institucional. El resultado queda en el estado por si la
/// UI quiere leerlo; el error se propaga para que la pantalla muestre el
/// `message` de `ApiException`.
class CreateUserNotifier extends AsyncNotifier<PublicUser?> {
  @override
  Future<PublicUser?> build() async => null;

  Future<PublicUser> create(CreateUserRequest request) async {
    final user = await ref.read(userRepositoryProvider).create(request);
    ref.invalidate(usersProvider);
    state = AsyncData(user);
    return user;
  }
}

final createUserProvider = AsyncNotifierProvider<CreateUserNotifier, PublicUser?>(
  CreateUserNotifier.new,
);

/// Suspensión y reactivación de una cuenta. Tras el cambio se invalida el
/// listado para que la fila se refresque sin reiniciar la app.
class SetUserSuspensionNotifier extends AsyncNotifier<PublicUser?> {
  @override
  Future<PublicUser?> build() async => null;

  Future<PublicUser> setSuspension(String id, {required bool suspended}) async {
    final user = await ref
        .read(userRepositoryProvider)
        .setSuspension(id, suspended: suspended);
    ref.invalidate(usersProvider);
    state = AsyncData(user);
    return user;
  }
}

final setUserSuspensionProvider =
    AsyncNotifierProvider<SetUserSuspensionNotifier, PublicUser?>(
      SetUserSuspensionNotifier.new,
    );
