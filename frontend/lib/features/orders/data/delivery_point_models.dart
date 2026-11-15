/// Puntos de entrega (RF-45) y cobertura (RU-02). Contrato en
/// `backend/src/delivery-points/` (`GET /delivery-points`).
library;

import 'package:latlong2/latlong.dart';

import 'fallback_models.dart';

/// Qué le dice Nest al solicitante según dónde está.
enum Coverage {
  covered('covered'),

  /// Zona urbana o anillo del aeródromo: no se entrega con dron.
  urban('urban'),

  /// Ningún punto activo al alcance de un nodo.
  noPoint('no_point'),
  unknown('unknown');

  const Coverage(this.apiValue);

  final String apiValue;

  static Coverage fromJson(Object? value) => values.firstWhere(
    (coverage) => coverage.apiValue == value,
    orElse: () => unknown,
  );
}

/// Un lugar fijo de la red donde baja el dron: despejado y con observador.
class DeliveryPoint {
  const DeliveryPoint({
    required this.id,
    required this.name,
    required this.municipality,
    required this.location,
    this.available = true,
    this.distanceKm,
    this.corridorZone,
  });

  factory DeliveryPoint.fromJson(Map<String, dynamic> json) {
    final corridor = json['corridor'];
    return DeliveryPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      municipality: json['municipality'] as String? ?? '',
      location: LatLng(
        _asDouble(json['latitude']),
        _asDouble(json['longitude']),
      ),
      available: json['available'] as bool? ?? true,
      distanceKm: _asDoubleOrNull(json['distanceKm']),
      corridorZone: corridor is Map<String, dynamic>
          ? corridor['zoneName'] as String?
          : null,
    );
  }

  final String id;
  final String name;
  final String municipality;
  final LatLng location;

  /// Activo y con su nodo activo.
  final bool available;

  /// Del GPS del solicitante al punto; `null` sin GPS.
  final double? distanceKm;

  /// La zona coordinada con corredor pactado (Atánquez, Guatapurí), si
  /// el punto está en una.
  final String? corridorZone;
}

/// La respuesta de `GET /delivery-points`: si hay cobertura, el punto que
/// se propone, los puntos y, sin cobertura, la alternativa terrestre.
class CoverageResult {
  const CoverageResult({
    required this.coverage,
    this.message,
    this.nearestPointId,
    this.points = const [],
    this.alternatives = const [],
  });

  factory CoverageResult.fromJson(Map<String, dynamic> json) {
    final points = json['points'];
    final alternatives = json['alternatives'];
    return CoverageResult(
      coverage: Coverage.fromJson(json['coverage']),
      message: json['message'] as String?,
      nearestPointId: json['nearestPointId'] as String?,
      points: [
        if (points is List)
          for (final row in points.whereType<Map<String, dynamic>>())
            DeliveryPoint.fromJson(row),
      ],
      alternatives: [
        if (alternatives is List)
          for (final row in alternatives.whereType<Map<String, dynamic>>())
            FallbackOption.fromJson(row),
      ],
    );
  }

  final Coverage coverage;

  /// Por qué no hay cobertura, en español del servidor.
  final String? message;

  /// El punto disponible más cercano al GPS; `null` sin GPS o sin cobertura.
  final String? nearestPointId;
  final List<DeliveryPoint> points;

  /// Centrales donde recoger el medicamento (RF-18).
  final List<FallbackOption> alternatives;

  /// Se puede pedir: hay cobertura. Un valor que la app no conoce no
  /// bloquea; Nest valida al crear.
  bool get canOrder =>
      coverage == Coverage.covered || coverage == Coverage.unknown;

  /// Los puntos que se pueden elegir.
  List<DeliveryPoint> get choices => [
    for (final point in points)
      if (point.available) point,
  ];

  DeliveryPoint? get nearest {
    for (final point in choices) {
      if (point.id == nearestPointId) return point;
    }
    return null;
  }
}

double _asDouble(Object? value) => _asDoubleOrNull(value) ?? 0;

double? _asDoubleOrNull(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
