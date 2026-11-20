/// Modelos de geovalla (RF-21).
///
/// El contrato lo define `toPublicGeofence` (`geofence.presenter.ts`) en
/// Nest. Toda geovalla tiene una **clase** (legal, operativa o temporal) y
/// una **forma** (círculo o vértices); el `polygon` siempre viene y es lo
/// que rodean las rutas. No hay `hubId`: las geovallas son de la operación.
library;

/// Polígono GeoJSON: el anillo exterior en `coordinates[0]`, con cada punto
/// en `[longitud, latitud]`, que es el orden de GeoJSON y no el de un mapa.
class GeoJsonPolygon {
  const GeoJsonPolygon(this.coordinates);

  factory GeoJsonPolygon.fromJson(Map<String, dynamic> json) {
    final raw = json['coordinates'];
    if (raw is! List) {
      throw const FormatException('El polígono debe incluir coordenadas.');
    }
    return GeoJsonPolygon([for (final ring in raw) _asRing(ring)]);
  }

  /// `coordinates[0]`, el anillo exterior.
  List<List<double>> get ring =>
      coordinates.isEmpty ? const [] : coordinates.first;

  /// Los vértices sin repetir el punto de cierre.
  List<List<double>> get vertices {
    final points = ring;
    if (points.length > 1 && _samePoint(points.first, points.last)) {
      return points.sublist(0, points.length - 1);
    }
    return points;
  }

  Map<String, dynamic> toJson() => {
    'type': 'Polygon',
    'coordinates': coordinates,
  };

  final List<List<List<double>>> coordinates;
}

/// Un punto como lo pide Nest en `center` y `vertices`.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  /// Desde `[longitud, latitud]` (GeoJSON y el modo dibujar).
  factory GeoPoint.fromLngLat(List<double> point) =>
      GeoPoint(latitude: point[1], longitude: point[0]);

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  final double latitude;
  final double longitude;

  List<double> toLngLat() => [longitude, latitude];

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// RF-21: quién la gestiona. Las tres primeras son las zonas legales.
enum GeofenceClass {
  aerodrome('aerodrome', 'Aeropuerto'),
  prohibited('prohibited', 'Prohibida'),
  heliport('heliport', 'Helipuerto'),
  operational('operational', 'Operativa'),
  temporary('temporary', 'Temporal');

  const GeofenceClass(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isLegal =>
      this == aerodrome || this == prohibited || this == heliport;

  static const legal = [aerodrome, prohibited, heliport];

  static GeofenceClass fromJson(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => operational,
  );
}

enum GeofenceShape {
  circle('circle', 'Círculo'),
  polygon('polygon', 'Vértices');

  const GeofenceShape(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static GeofenceShape fromJson(Object? value) =>
      value == 'circle' ? circle : polygon;
}

/// RF-21: por qué el operador cierra una zona que la norma no cierra.
enum OperationalCategory {
  works('works', 'Obra'),
  crowd('crowd', 'Aglomeración'),
  interference('interference', 'Interferencia'),
  groundRisk('ground_risk', 'Riesgo en tierra'),
  other('other', 'Otra');

  const OperationalCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OperationalCategory? fromJson(Object? value) {
    for (final item in values) {
      if (item.apiValue == value) return item;
    }
    return null;
  }
}

/// Límites de forma de `geofence-shape.rules.ts`.
abstract final class GeofenceLimits {
  static const radiusMinM = 50;
  static const radiusMaxM = 5000;
  static const verticesMin = 3;
  static const verticesMax = 50;
}

class Geofence {
  const Geofence({
    required this.id,
    required this.geofenceClass,
    required this.shape,
    required this.name,
    required this.polygon,
    this.reason,
    this.category,
    this.center,
    this.radiusM,
    this.code,
    this.legalBasis,
    this.source,
    this.active = true,
    this.createdByUserId,
    this.updatedByUserId,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    final center = json['center'];
    return Geofence(
      id: json['id'] as String,
      geofenceClass: GeofenceClass.fromJson(json['class']),
      shape: GeofenceShape.fromJson(json['shape']),
      name: json['name'] as String,
      reason: json['reason'] as String?,
      category: OperationalCategory.fromJson(json['category']),
      center: center is Map
          ? GeoPoint.fromJson(Map<String, dynamic>.from(center))
          : null,
      radiusM: (json['radiusM'] as num?)?.toInt(),
      polygon: GeoJsonPolygon.fromJson(_asMap(json['polygon'])),
      code: json['code'] as String?,
      legalBasis: json['legalBasis'] as String?,
      source: json['source'] as String?,
      active: json['active'] as bool? ?? true,
      createdByUserId: json['createdByUserId'] as String?,
      updatedByUserId: json['updatedByUserId'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      expiresAt: DateTime.tryParse('${json['expiresAt']}'),
    );
  }

  final String id;
  final GeofenceClass geofenceClass;
  final GeofenceShape shape;
  final String name;

  /// Operativa y temporal.
  final String? reason;
  final OperationalCategory? category;

  /// Solo un círculo.
  final GeoPoint? center;
  final int? radiusM;
  final GeoJsonPolygon polygon;

  /// Zona legal (RF-43).
  final String? code;
  final String? legalBasis;
  final String? source;

  /// Una zona legal desactivada no bloquea rutas.
  final bool active;
  final String? createdByUserId;
  final String? updatedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vigencia de una operativa o vencimiento de una temporal.
  final DateTime? expiresAt;

  bool get isLegal => geofenceClass.isLegal;
  bool get isOperational => geofenceClass == GeofenceClass.operational;
  bool get isTemporary => geofenceClass == GeofenceClass.temporary;
  bool get isCircle => shape == GeofenceShape.circle;

  /// Los vértices `[longitud, latitud]` de un polígono.
  List<List<double>> get vertices => polygon.vertices;
}

/// La geometría de un formulario: centro y radio, o vértices.
class GeofenceGeometry {
  const GeofenceGeometry.circle({required this.center, required this.radiusM})
    : shape = GeofenceShape.circle,
      vertices = const [];

  const GeofenceGeometry.polygon(this.vertices)
    : shape = GeofenceShape.polygon,
      center = null,
      radiusM = null;

  final GeofenceShape shape;
  final GeoPoint? center;
  final int? radiusM;
  final List<GeoPoint> vertices;

  /// `true` si describe la misma forma que tiene [geofence].
  bool sameAs(Geofence geofence) {
    if (shape != geofence.shape) return false;
    if (shape == GeofenceShape.circle) {
      return center == geofence.center && radiusM == geofence.radiusM;
    }
    final current = [
      for (final point in geofence.vertices) GeoPoint.fromLngLat(point),
    ];
    if (current.length != vertices.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != vertices[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'shape': shape.apiValue,
    if (shape == GeofenceShape.circle) ...{
      'center': center!.toJson(),
      'radiusM': radiusM,
    } else
      'vertices': [for (final point in vertices) point.toJson()],
  };
}

/// Body de `POST /geofences`: una operativa.
class CreateGeofenceRequest {
  const CreateGeofenceRequest({
    required this.name,
    required this.reason,
    required this.category,
    required this.geometry,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'reason': reason,
    'category': category.apiValue,
    ...geometry.toJson(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
  };

  final String name;
  final String reason;
  final OperationalCategory category;
  final GeofenceGeometry geometry;
  final DateTime? expiresAt;
}

/// Body de `PATCH /geofences/:id`. Va por diff: Nest responde 400 con un
/// cuerpo sin cambios. [clearExpiry] envía `expiresAt: null`.
class UpdateGeofenceRequest {
  const UpdateGeofenceRequest({
    this.name,
    this.reason,
    this.category,
    this.geometry,
    this.expiresAt,
    this.clearExpiry = false,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (reason != null) 'reason': reason,
    if (category != null) 'category': category!.apiValue,
    if (geometry != null) ...geometry!.toJson(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
    if (clearExpiry) 'expiresAt': null,
  };

  bool get isEmpty =>
      name == null &&
      reason == null &&
      category == null &&
      geometry == null &&
      expiresAt == null &&
      !clearExpiry;

  final String? name;
  final String? reason;
  final OperationalCategory? category;
  final GeofenceGeometry? geometry;
  final DateTime? expiresAt;
  final bool clearExpiry;
}

/// Body de `POST /geofences/legal` (RU-36, solo admin).
class CreateLegalZoneRequest {
  const CreateLegalZoneRequest({
    required this.code,
    required this.geofenceClass,
    required this.name,
    required this.legalBasis,
    required this.source,
    required this.geometry,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'class': geofenceClass.apiValue,
    'name': name,
    'legalBasis': legalBasis,
    'source': source,
    ...geometry.toJson(),
  };

  final String code;
  final GeofenceClass geofenceClass;
  final String name;
  final String legalBasis;
  final String source;
  final GeofenceGeometry geometry;
}

/// Body de `PATCH /geofences/legal/:id`: el motivo siempre va.
class UpdateLegalZoneRequest {
  const UpdateLegalZoneRequest({
    required this.reason,
    this.geofenceClass,
    this.name,
    this.legalBasis,
    this.source,
    this.geometry,
  });

  Map<String, dynamic> toJson() => {
    'reason': reason,
    if (geofenceClass != null) 'class': geofenceClass!.apiValue,
    if (name != null) 'name': name,
    if (legalBasis != null) 'legalBasis': legalBasis,
    if (source != null) 'source': source,
    if (geometry != null) ...geometry!.toJson(),
  };

  bool get hasChanges =>
      geofenceClass != null ||
      name != null ||
      legalBasis != null ||
      source != null ||
      geometry != null;

  final String reason;
  final GeofenceClass? geofenceClass;
  final String? name;
  final String? legalBasis;
  final String? source;
  final GeofenceGeometry? geometry;
}

/// RU-36: una fila del historial de una zona legal.
class GeofenceChange {
  const GeofenceChange({
    required this.id,
    required this.action,
    required this.fields,
    this.reason,
    this.createdAt,
  });

  factory GeofenceChange.fromJson(Map<String, dynamic> json) {
    final changes = json['changes'];
    return GeofenceChange(
      id: json['id'] as String,
      action: GeofenceChangeAction.fromJson(json['action']),
      reason: json['reason'] as String?,
      fields: changes is Map ? changes.keys.cast<String>().toList() : const [],
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  final String id;
  final GeofenceChangeAction action;
  final String? reason;

  /// Los campos que cambiaron (`name`, `radiusM`, `geometry`…).
  final List<String> fields;
  final DateTime? createdAt;
}

enum GeofenceChangeAction {
  created('created', 'Creada'),
  updated('updated', 'Editada'),
  deactivated('deactivated', 'Desactivada'),
  reactivated('reactivated', 'Reactivada');

  const GeofenceChangeAction(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static GeofenceChangeAction fromJson(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => updated,
  );
}

/// Cómo se nombra en pantalla un campo del historial.
String changeFieldLabel(String field) => switch (field) {
  'class' => 'clase',
  'name' => 'nombre',
  'legalBasis' => 'base legal',
  'source' => 'fuente',
  'shape' => 'forma',
  'center' => 'centro',
  'radiusM' => 'radio',
  'active' => 'estado',
  'geometry' => 'área',
  _ => field,
};

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
