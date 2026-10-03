/// Modelos de geovalla.
///
/// El contrato lo define `GeofencesService.toPublicGeofence` en Nest:
/// `id`, `name`, `reason`, `polygon`, `createdByUserId` y `createdAt`.
/// No hay `hubId`: las geovallas no pertenecen a una central; cualquier
/// operador activo ve todas, ordenadas por nombre.
library;

/// Polígono GeoJSON (`GeoJsonPolygonDto`): `type` fijo en `Polygon` y el
/// anillo exterior en `coordinates[0]`, con cada punto en
/// `[longitud, latitud]`, que es el orden de GeoJSON y no el de un mapa.
class GeoJsonPolygon {
  const GeoJsonPolygon(this.coordinates);

  factory GeoJsonPolygon.fromJson(Map<String, dynamic> json) {
    final raw = json['coordinates'];
    if (raw is! List) {
      throw const FormatException('El polígono debe incluir coordenadas.');
    }
    return GeoJsonPolygon([for (final ring in raw) _asRing(ring)]);
  }

  /// Cierra el anillo desde los vértices que escribe el usuario: con 3 o
  /// más puntos copia el primero al final, que es lo que Nest exige (al
  /// menos 4 puntos y cerrado). Con menos no se inventa geometría y el
  /// backend responde con su mensaje.
  factory GeoJsonPolygon.fromVertices(List<List<double>> vertices) {
    final ring = [for (final point in vertices) List<double>.of(point)];
    if (ring.length >= 3 && !_samePoint(ring.first, ring.last)) {
      ring.add(List<double>.of(ring.first));
    }
    return GeoJsonPolygon([ring]);
  }

  /// `coordinates[0]`, el anillo exterior. Vacío si el polígono vino mal
  /// formado, para que la UI pueda mostrar el mensaje de Nest.
  List<List<double>> get ring =>
      coordinates.isEmpty ? const [] : coordinates.first;

  /// Los vértices como los edita el formulario: el anillo sin repetir el
  /// punto de cierre. Al guardar, [GeoJsonPolygon.fromVertices] lo vuelve
  /// a armar.
  List<List<double>> get vertices {
    final points = ring;
    if (points.length > 1 && _samePoint(points.first, points.last)) {
      return points.sublist(0, points.length - 1);
    }
    return points;
  }

  /// `true` si el otro polígono tiene exactamente los mismos puntos.
  /// `==` de lista es identidad, y el diff del formulario necesita saber
  /// si el usuario no movió ningún vértice.
  bool hasSameRing(GeoJsonPolygon other) {
    final mine = ring;
    final theirs = other.ring;
    if (mine.length != theirs.length) return false;
    for (var i = 0; i < mine.length; i++) {
      final left = mine[i];
      final right = theirs[i];
      if (left.length != right.length) return false;
      for (var j = 0; j < left.length; j++) {
        if (left[j] != right[j]) return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'type': 'Polygon',
    'coordinates': coordinates,
  };

  final List<List<List<double>>> coordinates;
}

class Geofence {
  const Geofence({
    required this.id,
    required this.name,
    required this.reason,
    required this.polygon,
    this.createdByUserId,
    this.createdAt,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String,
      polygon: GeoJsonPolygon.fromJson(_asMap(json['polygon'])),
      createdByUserId: json['createdByUserId'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  final String id;
  final String name;
  final String reason;
  final GeoJsonPolygon polygon;
  final String? createdByUserId;
  final DateTime? createdAt;
}

/// Body de `POST /geofences`.
class CreateGeofenceRequest {
  const CreateGeofenceRequest({
    required this.name,
    required this.reason,
    required this.polygon,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'reason': reason,
    'polygon': polygon.toJson(),
  };

  final String name;
  final String reason;
  final GeoJsonPolygon polygon;
}

/// Body de `PATCH /geofences/:id`. Va por diff: Nest responde
/// `Debes enviar al menos un campo para actualizar.` con un body vacío,
/// así que los campos que no cambian no se envían.
class UpdateGeofenceRequest {
  const UpdateGeofenceRequest({this.name, this.reason, this.polygon});

  Map<String, dynamic> toJson() {
    final polygon = this.polygon;
    return {
      if (name != null) 'name': name,
      if (reason != null) 'reason': reason,
      if (polygon != null) 'polygon': polygon.toJson(),
    };
  }

  bool get isEmpty => name == null && reason == null && polygon == null;

  final String? name;
  final String? reason;
  final GeoJsonPolygon? polygon;
}

bool _samePoint(List<double> a, List<double> b) => a[0] == b[0] && a[1] == b[1];

List<List<double>> _asRing(Object? ring) {
  if (ring is! List) {
    throw const FormatException('El anillo del polígono no es válido.');
  }
  return [for (final point in ring) _asPoint(point)];
}

List<double> _asPoint(Object? point) {
  if (point is! List || point.length != 2) {
    throw const FormatException('Cada punto debe ser [longitud, latitud].');
  }
  final longitude = point[0];
  final latitude = point[1];
  if (longitude is! num || latitude is! num) {
    throw const FormatException('Cada punto debe ser [longitud, latitud].');
  }
  return [longitude.toDouble(), latitude.toDouble()];
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map<Object?, Object?>) return Map<String, dynamic>.from(value);
  throw const FormatException('La geovalla no trae polígono.');
}
