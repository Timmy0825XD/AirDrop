import 'package:flutter/material.dart';

import '../../data/geofence_models.dart';
import 'geofence_vertex.dart';

/// Los campos del formulario de geovallas en un solo objeto.
///
/// No pinta nada: conserva los controladores (nombre, motivo y las filas
/// de vértices), los libera, carga una geovalla existente y arma los
/// body de `POST /geofences` y de `PATCH /geofences/:id`.
class GeofenceFormValues {
  final name = TextEditingController();
  final reason = TextEditingController();

  /// Filas `[longitud, latitud]` sin cierre; arrancan en 3 (el mínimo).
  final vertices = List.generate(3, (_) => GeofenceVertex());

  void dispose() {
    name.dispose();
    reason.dispose();
    for (final vertex in vertices) {
      vertex.dispose();
    }
  }

  /// Rellena el formulario al editar. Los vértices llegan **sin** el
  /// punto de cierre (`Geofence.polygon.vertices`) y solo corre la
  /// primera vez: si el provider se refresca, no pisa lo que el usuario
  /// esté escribiendo.
  void load(Geofence geofence) {
    name.text = geofence.name;
    reason.text = geofence.reason;
    for (final vertex in vertices) {
      vertex.dispose();
    }
    vertices
      ..clear()
      ..addAll(geofence.polygon.vertices.map(GeofenceVertex.fromPoint));
  }

  void addVertex() => vertices.add(GeofenceVertex());

  void removeVertex(int index) => vertices.removeAt(index).dispose();

  /// Body de `POST /geofences`: cierra el anillo con el primero al final.
  CreateGeofenceRequest request() {
    return CreateGeofenceRequest(
      name: name.text.trim(),
      reason: reason.text.trim(),
      polygon: GeoJsonPolygon.fromVertices(_points()),
    );
  }

  /// Body de `PATCH /geofences/:id` con **solo** los campos que cambiaron
  /// respecto de [geofence]. Si nada cambió, el request queda vacío y la
  /// pantalla no lo envía: Nest responde 400 con un cuerpo sin cambios.
  UpdateGeofenceRequest diff(Geofence geofence) {
    final nameText = name.text.trim();
    final reasonText = reason.text.trim();
    final polygon = GeoJsonPolygon.fromVertices(_points());
    return UpdateGeofenceRequest(
      name: nameText == geofence.name ? null : nameText,
      reason: reasonText == geofence.reason ? null : reasonText,
      polygon: polygon.hasSameRing(geofence.polygon) ? null : polygon,
    );
  }

  List<List<double>> _points() => [for (final vertex in vertices) vertex.point];
}
