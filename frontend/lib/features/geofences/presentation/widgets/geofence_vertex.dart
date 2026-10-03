import 'package:flutter/material.dart';

/// Una fila del formulario de geovallas: longitud y latitud como texto,
/// para que el campo pueda validarlas con `Validators` antes de
/// parsearlas. Vive fuera de `GeofenceFormValues` porque también la usa
/// `PolygonPointFields` al pintar cada renglón.
class GeofenceVertex {
  GeofenceVertex({String longitude = '', String latitude = ''})
    : longitude = TextEditingController(text: longitude),
      latitude = TextEditingController(text: latitude);

  factory GeofenceVertex.fromPoint(List<double> point) =>
      GeofenceVertex(longitude: '${point[0]}', latitude: '${point[1]}');

  final TextEditingController longitude;
  final TextEditingController latitude;

  /// El par `[longitud, latitud]` que espera GeoJSON.
  List<double> get point => [
    double.parse(longitude.text.trim()),
    double.parse(latitude.text.trim()),
  ];

  void dispose() {
    longitude.dispose();
    latitude.dispose();
  }
}
