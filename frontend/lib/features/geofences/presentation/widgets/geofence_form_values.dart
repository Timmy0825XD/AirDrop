import 'package:flutter/material.dart';

import '../../data/geofence_models.dart';

/// Los campos del formulario de geovallas en un solo objeto.
///
/// No pinta nada: conserva los controladores (nombre y motivo) y los
/// vértices que se dibujan en el mapa, carga una geovalla existente y arma
/// los body de `POST /geofences` y de `PATCH /geofences/:id`.
class GeofenceFormValues {
  final name = TextEditingController();
  final reason = TextEditingController();

  /// Vértices `[longitud, latitud]` sin el punto de cierre. Los pone el
  /// modo dibujar (`GeofenceDrawScreen`); arranca vacío.
  List<List<double>> vertices = [];

  void dispose() {
    name.dispose();
    reason.dispose();
  }

  /// Rellena el formulario al editar. Los vértices llegan **sin** el
  /// punto de cierre (`Geofence.polygon.vertices`).
  void load(Geofence geofence) {
    name.text = geofence.name;
    reason.text = geofence.reason;
    vertices = geofence.polygon.vertices;
  }

  /// Body de `POST /geofences`: cierra el anillo con el primero al final.
  CreateGeofenceRequest request() {
    return CreateGeofenceRequest(
      name: name.text.trim(),
      reason: reason.text.trim(),
      polygon: GeoJsonPolygon.fromVertices(vertices),
    );
  }

  /// Body de `PATCH /geofences/:id` con **solo** los campos que cambiaron
  /// respecto de [geofence]. Si nada cambió, el request queda vacío y la
  /// pantalla no lo envía: Nest responde 400 con un cuerpo sin cambios.
  UpdateGeofenceRequest diff(Geofence geofence) {
    final nameText = name.text.trim();
    final reasonText = reason.text.trim();
    final polygon = GeoJsonPolygon.fromVertices(vertices);
    return UpdateGeofenceRequest(
      name: nameText == geofence.name ? null : nameText,
      reason: reasonText == geofence.reason ? null : reasonText,
      polygon: polygon.hasSameRing(geofence.polygon) ? null : polygon,
    );
  }
}
