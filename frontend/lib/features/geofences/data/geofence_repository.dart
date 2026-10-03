import 'geofence_models.dart';

/// Contrato de la feature de geovallas. Las cuatro operaciones que
/// `GeofencesController` expone, todas solo para operador de flota.
///
/// No hay `mine()` ni ningún 404 que se convierta en `null`: una geovalla
/// inexistente es un error con el mensaje de Nest.
abstract class GeofenceRepository {
  /// `GET /geofences` — todas, ordenadas por nombre.
  Future<List<Geofence>> list();

  /// `POST /geofences` — alta del operador.
  Future<Geofence> create(CreateGeofenceRequest request);

  /// `PATCH /geofences/:id` — solo los campos enviados cambian.
  Future<Geofence> update(String id, UpdateGeofenceRequest request);

  /// `DELETE /geofences/:id` — responde `204` sin cuerpo.
  Future<void> remove(String id);
}
