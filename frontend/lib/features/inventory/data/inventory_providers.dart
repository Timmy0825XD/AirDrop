import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../hubs/data/hub_providers.dart';
import 'inventory_models.dart';
import 'inventory_repository.dart';
import 'local_inventory_repository.dart';
import 'remote_inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return switch (appDataSource) {
    // El repositorio local necesita la central del despachador para
    // replicar los 403 de `requireDispatcherHub`.
    DataSource.local => LocalInventoryRepository(
      hubRepository: ref.watch(hubRepositoryProvider),
    ),
    DataSource.remote => RemoteInventoryRepository(apiClient: apiClient),
  };
});

/// Listado de los ítems de la central del despachador. Cada mutación lo
/// invalida, así la pantalla se refresca sin reiniciar la app.
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).list();
});

/// Alta de ítem. El error se propaga para que la pantalla muestre el
/// `message` de `ApiException`.
class CreateInventoryNotifier extends AsyncNotifier<InventoryItem?> {
  @override
  Future<InventoryItem?> build() async => null;

  Future<InventoryItem> create(CreateInventoryItemRequest request) async {
    final item = await ref.read(inventoryRepositoryProvider).create(request);
    ref.invalidate(inventoryProvider);
    state = AsyncData(item);
    return item;
  }
}

final createInventoryProvider =
    AsyncNotifierProvider<CreateInventoryNotifier, InventoryItem?>(
      CreateInventoryNotifier.new,
    );

/// Edición de ítem. Solo se envían los campos cambiados. Se llama `edit`
/// y no `update` porque `AsyncNotifier` ya tiene un método `update`.
class UpdateInventoryNotifier extends AsyncNotifier<InventoryItem?> {
  @override
  Future<InventoryItem?> build() async => null;

  Future<InventoryItem> edit(
    String id,
    UpdateInventoryItemRequest request,
  ) async {
    final item = await ref
        .read(inventoryRepositoryProvider)
        .update(id, request);
    ref.invalidate(inventoryProvider);
    state = AsyncData(item);
    return item;
  }
}

final updateInventoryProvider =
    AsyncNotifierProvider<UpdateInventoryNotifier, InventoryItem?>(
      UpdateInventoryNotifier.new,
    );

/// Baja de ítem (`DELETE`, 204 sin cuerpo).
class DeleteInventoryNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String id) async {
    await ref.read(inventoryRepositoryProvider).remove(id);
    ref.invalidate(inventoryProvider);
  }
}

final deleteInventoryProvider =
    AsyncNotifierProvider<DeleteInventoryNotifier, void>(
      DeleteInventoryNotifier.new,
    );
