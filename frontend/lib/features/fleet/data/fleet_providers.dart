import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
import 'fleet_models.dart';
import 'fleet_repository.dart';
import 'local_fleet_repository.dart';
import 'remote_fleet_repository.dart';

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return switch (appDataSource) {
    // El repositorio local necesita el repositorio de centrales para
    // replicar `requireActive` y `assertAssigned` de Nest, y el token
    // para saber qué cuenta está operando.
    DataSource.local => LocalFleetRepository(
      hubRepository: ref.watch(hubRepositoryProvider),
      tokenStore: tokenStore,
    ),
    DataSource.remote => RemoteFleetRepository(apiClient: apiClient),
  };
});

/// Centrales que ve el operador. **No** reusa `hubsProvider`: ese sigue a
/// `hubFilterProvider`, que es el filtro del administrador, y
/// `GET /hubs` de un operador devuelve sus centrales sin filtrar por
/// estado (`HubsService.listAssigned`).
final assignedHubsProvider = FutureProvider<List<Hub>>((ref) {
  return ref.watch(hubRepositoryProvider).list();
});

/// Última central elegida por el operador en la pantalla de flota. `null`
/// mientras no se elige ninguna.
class FleetHubNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? hubId) => state = hubId;
}

final fleetHubProvider =
    NotifierProvider<FleetHubNotifier, String?>(FleetHubNotifier.new);

/// Central **efectiva**: la elegida por el operador o, si todavía no hay
/// selección válida, la primera asignada.
///
/// La auto-selección vive acá y no en el `build` de la pantalla, porque
/// mutar un provider mientras se construye el árbol provoca un ciclo en
/// Riverpod. Si la central elegida desaparece de la lista, se vuelve a la
/// primera.
final effectiveHubProvider = Provider<Hub?>((ref) {
  final hubs = ref.watch(assignedHubsProvider).asData?.value;
  if (hubs == null || hubs.isEmpty) return null;

  final selected = ref.watch(fleetHubProvider);
  for (final hub in hubs) {
    if (hub.id == selected) return hub;
  }
  return hubs.first;
});

/// Modelos de dron sembrados en la base. El formulario muestra `name` y
/// guarda `id`.
final fleetModelsProvider = FutureProvider<List<DroneModel>>((ref) {
  return ref.watch(fleetRepositoryProvider).listModels();
});

/// Drones de la central efectiva. Sin central no se consulta nada: mandar
/// `GET /fleet/drones` sin `hubId` responde `400 La central no es válida.`
final dronesProvider = FutureProvider<List<Drone>>((ref) {
  final hubId = ref.watch(effectiveHubProvider)?.id;
  if (hubId == null) return const <Drone>[];
  return ref.watch(fleetRepositoryProvider).listDrones(hubId);
});

/// Alta de dron. El error se propaga para que la pantalla muestre el
/// `message` de `ApiException`.
class CreateDroneNotifier extends AsyncNotifier<Drone?> {
  @override
  Future<Drone?> build() async => null;

  Future<Drone> create(CreateDroneRequest request) async {
    final drone = await ref.read(fleetRepositoryProvider).create(request);
    ref.invalidate(dronesProvider);
    state = AsyncData(drone);
    return drone;
  }
}

final createDroneProvider = AsyncNotifierProvider<CreateDroneNotifier, Drone?>(
  CreateDroneNotifier.new,
);

/// Cambio de estado (`PATCH .../status`). Una sola vía por botón: quien
/// quiere registrar un mantenimiento usa [registerMaintenanceProvider].
class UpdateDroneStatusNotifier extends AsyncNotifier<Drone?> {
  @override
  Future<Drone?> build() async => null;

  Future<Drone> set(String id, UpdateDroneStatusRequest request) async {
    final drone = await ref
        .read(fleetRepositoryProvider)
        .updateStatus(id, request);
    ref.invalidate(dronesProvider);
    state = AsyncData(drone);
    return drone;
  }
}

final updateDroneStatusProvider =
    AsyncNotifierProvider<UpdateDroneStatusNotifier, Drone?>(
      UpdateDroneStatusNotifier.new,
    );

/// Registro de mantenimiento (`POST .../maintenance`): motivo y fecha
/// obligatorios, el dron queda `out_of_service`.
class RegisterMaintenanceNotifier extends AsyncNotifier<Drone?> {
  @override
  Future<Drone?> build() async => null;

  Future<Drone> register(
    String id,
    RegisterMaintenanceRequest request,
  ) async {
    final drone = await ref
        .read(fleetRepositoryProvider)
        .registerMaintenance(id, request);
    ref.invalidate(dronesProvider);
    state = AsyncData(drone);
    return drone;
  }
}

final registerMaintenanceProvider =
    AsyncNotifierProvider<RegisterMaintenanceNotifier, Drone?>(
      RegisterMaintenanceNotifier.new,
    );
