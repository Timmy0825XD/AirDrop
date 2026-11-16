import 'geofence_models.dart';

/// RF-43: una zona legal de la región (`GET /airspace/zones`). Viene con el
/// escenario: el operador la ve en su lista y en el mapa, pero no la crea,
/// no la edita ni la borra (es la norma, no una decisión de la central).
class LegalZone {
  const LegalZone({
    required this.code,
    required this.kind,
    required this.name,
    required this.legalBasis,
    required this.source,
    required this.polygon,
  });

  factory LegalZone.fromJson(Map<String, dynamic> json) {
    final polygon = json['polygon'];
    return LegalZone(
      code: json['code'] as String? ?? '',
      kind: LegalZoneKind.fromJson(json['kind']),
      name: json['name'] as String? ?? '',
      legalBasis: json['legalBasis'] as String? ?? '',
      source: json['source'] as String? ?? '',
      polygon: polygon is Map<String, dynamic>
          ? GeoJsonPolygon.fromJson(polygon)
          : const GeoJsonPolygon([]),
    );
  }

  final String code;
  final LegalZoneKind kind;
  final String name;

  /// El artículo que la respalda: "RAC 100.315(a)(13): …".
  final String legalBasis;

  /// De dónde sale el dato (OpenStreetMap, AIP, lista de la Policía).
  final String source;
  final GeoJsonPolygon polygon;
}

/// Los tipos de zona de la demo; `unknown` si Nest manda uno nuevo.
enum LegalZoneKind {
  aerodrome('aerodrome', 'Aeropuerto'),
  prohibited('prohibited', 'Prohibida'),
  heliport('heliport', 'Helipuerto'),
  unknown('unknown', 'Zona legal');

  const LegalZoneKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LegalZoneKind fromJson(Object? value) => values.firstWhere(
    (kind) => kind.apiValue == value,
    orElse: () => unknown,
  );
}
