import '../../data/geofence_models.dart';
import '../../data/local_geofence_repository.dart';

/// La forma que se está editando (RF-21): un círculo (centro y radio) o un
/// polígono de vértices. No pinta nada; la comparten el formulario de la
/// operativa y el de la zona legal.
class GeometryDraft {
  GeofenceShape shape = GeofenceShape.polygon;

  /// `[longitud, latitud]`, sin el punto de cierre.
  List<List<double>> vertices = [];
  GeoPoint? center;
  int radiusM = 200;

  void load(Geofence geofence) {
    shape = geofence.shape;
    if (geofence.isCircle) {
      center = geofence.center;
      radiusM = geofence.radiusM ?? radiusM;
    } else {
      vertices = geofence.vertices;
    }
  }

  /// El mensaje de error de la forma, o `null` si está completa.
  String? validate() {
    if (shape == GeofenceShape.circle) {
      if (center == null) return 'Toca el mapa para poner el centro.';
      if (radiusM < GeofenceLimits.radiusMinM ||
          radiusM > GeofenceLimits.radiusMaxM) {
        return 'El radio debe estar entre 50 m y 5 km.';
      }
      return null;
    }
    if (vertices.length < GeofenceLimits.verticesMin) {
      return 'Dibuja al menos 3 vértices en el mapa.';
    }
    if (vertices.length > GeofenceLimits.verticesMax) {
      return 'El polígono admite hasta 50 vértices.';
    }
    return null;
  }

  GeofenceGeometry toGeometry() => shape == GeofenceShape.circle
      ? GeofenceGeometry.circle(center: center!, radiusM: radiusM)
      : GeofenceGeometry.polygon([
          for (final point in vertices) GeoPoint.fromLngLat(point),
        ]);

  /// El polígono para la vista previa (el círculo, aproximado).
  List<List<double>> get previewRing {
    if (shape == GeofenceShape.polygon) return vertices;
    if (center == null) return const [];
    return localPolygonOf(toGeometry()).vertices;
  }
}

/// "200 m" o "1,5 km".
String formatRadius(int meters) {
  if (meters < 1000) return '$meters m';
  final km = (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1);
  return '${km.replaceAll('.', ',')} km';
}
