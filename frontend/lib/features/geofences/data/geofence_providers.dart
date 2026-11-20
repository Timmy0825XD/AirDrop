import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../auth/presentation/auth_controller.dart';
import 'geofence_models.dart';
import 'geofence_repository.dart';
import 'legal_zone_models.dart';
import 'legal_zone_repository.dart';
import 'local_geofence_repository.dart';
import 'remote_geofence_repository.dart';

/// Único sitio donde se decide si la feature habla con Nest o con los
/// fixtures locales.
final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  // Otra cuenta, otro repositorio: lo cargado por la anterior se descarta.
  ref.watch(sessionUserIdProvider);
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return switch (appDataSource) {
    DataSource.local => LocalGeofenceRepository(tokenStore: tokenStore),
    DataSource.remote => RemoteGeofenceRepository(apiClient: apiClient),
  };
});

/// RF-43: de dónde salen las zonas legales. Mismo interruptor de origen.
final legalZoneRepositoryProvider = Provider<LegalZoneRepository>((ref) {
  ref.watch(sessionUserIdProvider);
  return switch (appDataSource) {
    DataSource.local => LocalLegalZoneRepository(),
    DataSource.remote => RemoteLegalZoneRepository(
      apiClient: ref.watch(apiClientProvider),
    ),
  };
});

/// Las zonas legales activas para el mapa de flota (`GET /airspace/zones`).
final legalZonesProvider = FutureProvider<List<LegalZone>>((ref) {
  return ref.watch(legalZoneRepositoryProvider).list();
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

/// RU-36: el historial de una zona legal.
final geofenceChangesProvider =
    FutureProvider.family<List<GeofenceChange>, String>((ref, id) {
      return ref.watch(geofenceRepositoryProvider).changes(id);
    });

/// RU-36 y CU-52: el admin mantiene las zonas legales. Cada cambio refresca
/// el catálogo, el historial y las zonas del mapa de flota.
class LegalZoneAdminNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Geofence> create(CreateLegalZoneRequest request) =>
      _run(() => ref.read(geofenceRepositoryProvider).createLegal(request));

  Future<Geofence> edit(String id, UpdateLegalZoneRequest request) => _run(
    () => ref.read(geofenceRepositoryProvider).updateLegal(id, request),
    id: id,
  );

  Future<Geofence> setActive(
    String id, {
    required bool active,
    required String reason,
  }) => _run(
    () => ref
        .read(geofenceRepositoryProvider)
        .setLegalActive(id, active: active, reason: reason),
    id: id,
  );

  Future<Geofence> _run(Future<Geofence> Function() call, {String? id}) async {
    final zone = await call();
    ref.invalidate(geofencesProvider);
    ref.invalidate(legalZonesProvider);
    if (id != null) ref.invalidate(geofenceChangesProvider(id));
    return zone;
  }
}

final legalZoneAdminProvider =
    AsyncNotifierProvider<LegalZoneAdminNotifier, void>(
      LegalZoneAdminNotifier.new,
    );
