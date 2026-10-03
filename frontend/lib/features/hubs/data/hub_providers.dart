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

/// Filtro del listado del administrador: `null` es "Todas".
class HubFilterNotifier extends Notifier<HubStatus?> {
  @override
  HubStatus? build() => null;

  void select(HubStatus? status) => state = status;
}

final hubFilterProvider =
    NotifierProvider<HubFilterNotifier, HubStatus?>(HubFilterNotifier.new);

/// Listado de centrales. Sigue al filtro, así que un solo `invalidate`
/// de este provider refresca lo que se vea en pantalla.
final hubsProvider = FutureProvider<List<Hub>>((ref) {
  final status = ref.watch(hubFilterProvider);
  return ref.watch(hubRepositoryProvider).list(status: status);
});

/// Central del despachador. `null` cuando Nest responde 404.
final myHubProvider = FutureProvider<Hub?>((ref) {
  return ref.watch(hubRepositoryProvider).mine();
});

/// Alta de central. El resultado queda en el estado por si la UI quiere
/// leerlo; el error se propaga para que la pantalla muestre el `message`
/// de `ApiException`.
class CreateHubNotifier extends AsyncNotifier<Hub?> {
  @override
  Future<Hub?> build() async => null;

  Future<Hub> create(CreateHubRequest request) async {
    final hub = await ref.read(hubRepositoryProvider).create(request);
    ref.invalidate(hubsProvider);
    state = AsyncData(hub);
    return hub;
  }
}

final createHubProvider = AsyncNotifierProvider<CreateHubNotifier, Hub?>(
  CreateHubNotifier.new,
);

/// Suspensión y reactivación de una central. Tras el cambio se invalidan
/// el listado **y** `myHubProvider`, para que el despachador vea su
/// central con el estado nuevo sin reiniciar la app.
class SetHubSuspensionNotifier extends AsyncNotifier<Hub?> {
  @override
  Future<Hub?> build() async => null;

  Future<Hub> setSuspension(String id, {required bool suspended}) async {
    final hub = await ref
        .read(hubRepositoryProvider)
        .setSuspension(id, suspended: suspended);
    ref.invalidate(hubsProvider);
    ref.invalidate(myHubProvider);
    state = AsyncData(hub);
    return hub;
  }
}

final setHubSuspensionProvider =
    AsyncNotifierProvider<SetHubSuspensionNotifier, Hub?>(
      SetHubSuspensionNotifier.new,
    );
