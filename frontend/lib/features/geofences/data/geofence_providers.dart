import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import 'geofence_models.dart';
import 'geofence_repository.dart';
import 'local_geofence_repository.dart';
import 'remote_geofence_repository.dart';

/// Único sitio donde se decide si la feature habla con Nest o con los
/// fixtures locales.
final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return switch (appDataSource) {
    DataSource.local => LocalGeofenceRepository(tokenStore: tokenStore),
    DataSource.remote => RemoteGeofenceRepository(apiClient: apiClient),
  };
});

/// Listado de geovallas. Cada mutación lo invalida, así la pantalla se
/// refresca sin reiniciar la app.
final geofencesProvider = FutureProvider<List<Geofence>>((ref) {
  return ref.watch(geofenceRepositoryProvider).list();
});

/// Alta de geovalla. El error se propaga para que la pantalla muestre el
/// `message` de `ApiException`.
class CreateGeofenceNotifier extends AsyncNotifier<Geofence?> {
  @override
  Future<Geofence?> build() async => null;

  Future<Geofence> create(CreateGeofenceRequest request) async {
    final geofence = await ref.read(geofenceRepositoryProvider).create(request);
    ref.invalidate(geofencesProvider);
    state = AsyncData(geofence);
    return geofence;
  }
}

final createGeofenceProvider =
    AsyncNotifierProvider<CreateGeofenceNotifier, Geofence?>(
      CreateGeofenceNotifier.new,
    );

/// Edición de geovalla. Se llama `edit` y no `update` porque
/// `AsyncNotifier` ya tiene un método `update`. Solo se envían los
/// campos cambiados.
class UpdateGeofenceNotifier extends AsyncNotifier<Geofence?> {
  @override
  Future<Geofence?> build() async => null;

  Future<Geofence> edit(String id, UpdateGeofenceRequest request) async {
    final geofence = await ref
        .read(geofenceRepositoryProvider)
        .update(id, request);
    ref.invalidate(geofencesProvider);
    state = AsyncData(geofence);
    return geofence;
  }
}

final updateGeofenceProvider =
    AsyncNotifierProvider<UpdateGeofenceNotifier, Geofence?>(
      UpdateGeofenceNotifier.new,
    );

/// Baja de geovalla (`DELETE`, 204 sin cuerpo).
class DeleteGeofenceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String id) async {
    await ref.read(geofenceRepositoryProvider).remove(id);
    ref.invalidate(geofencesProvider);
  }
}

final deleteGeofenceProvider =
    AsyncNotifierProvider<DeleteGeofenceNotifier, void>(
      DeleteGeofenceNotifier.new,
    );
