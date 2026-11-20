import 'geofence_models.dart';

/// Contrato de la feature de geovallas (RF-21, RU-19, RU-36).
///
/// El operador y el admin leen el catálogo; el operador gestiona las
/// operativas y el admin las zonas legales. Una geovalla inexistente es un
/// error con el mensaje de Nest.
abstract class GeofenceRepository {
  /// `GET /geofences` — legales (con `active`) y operativas vigentes.
  Future<List<Geofence>> list();

  /// `GET /geofences/:id/changes` — historial de una zona legal.
  Future<List<GeofenceChange>> changes(String id);

  /// `POST /geofences` — operativa (operador).
  Future<Geofence> create(CreateGeofenceRequest request);

  /// `PATCH /geofences/:id` — solo los campos enviados cambian.
  Future<Geofence> update(String id, UpdateGeofenceRequest request);

  /// `DELETE /geofences/:id` — responde `204` sin cuerpo.
  Future<void> remove(String id);

  /// `POST /geofences/legal` — zona legal (admin).
  Future<Geofence> createLegal(CreateLegalZoneRequest request);

  /// `PATCH /geofences/legal/:id` — con el motivo del cambio.
  Future<Geofence> updateLegal(String id, UpdateLegalZoneRequest request);

  /// `POST /geofences/legal/:id/deactivate|reactivate` — con motivo.
  Future<Geofence> setLegalActive(
    String id, {
    required bool active,
    required String reason,
  });
}
