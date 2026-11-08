/// El mapa en vivo del operador (§16 y §17 de `pendientes-backend.md`):
/// `GET /fleet/map` y los incidentes de `hub-incident`. De la central no
/// viajan dirección, contactos ni inventario; del vuelo, nada de quién
/// recibe ni qué lleva.
library;

import '../../geofences/data/geofence_models.dart' show GeoJsonPolygon;
import 'fleet_flight.dart';

/// Una central en el mapa con el conteo de su flota.
class FleetMapHub {
  const FleetMapHub({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.active,
    this.available = 0,
    this.inMission = 0,
    this.inShop = 0,
    this.total = 0,
  });

  factory FleetMapHub.fromJson(Map<String, dynamic> json) {
    final fleet = json['fleet'] is Map ? json['fleet'] as Map : const {};
    int count(String key) => (fleet[key] as num?)?.toInt() ?? 0;
    return FleetMapHub(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      active: json['status'] == 'active',
      available: count('available'),
      inMission: count('inMission'),
      // En taller o en tierra esperando el rescate (§17).
      inShop: count('maintenance') + count('outOfService') + count('grounded'),
      total: count('total'),
    );
  }

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool active;
  final int available;
  final int inMission;
  final int inShop;
  final int total;

  /// "3 drones · 1 en misión · 1 en taller".
  String get fleetLine => [
    total == 1 ? '1 dron' : '$total drones',
    if (inMission > 0) '$inMission en misión',
    if (inShop > 0) '$inShop en taller',
  ].join(' · ');
}

/// Una geovalla en el mapa: solo el nombre y el polígono.
class FleetMapGeofence {
  const FleetMapGeofence({required this.name, required this.polygon});

  factory FleetMapGeofence.fromJson(Map<String, dynamic> json) =>
      FleetMapGeofence(
        name: json['name'] as String? ?? '',
        polygon: GeoJsonPolygon.fromJson(
          Map<String, dynamic>.from(json['polygon'] as Map),
        ),
      );

  final String name;
  final GeoJsonPolygon polygon;
}

class FleetMap {
  const FleetMap({
    this.hubs = const [],
    this.geofences = const [],
    this.flights = const [],
  });

  factory FleetMap.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) => [
      for (final row in (json[key] as List?) ?? const [])
        Map<String, dynamic>.from(row as Map),
    ];
    return FleetMap(
      hubs: rows('hubs').map(FleetMapHub.fromJson).toList(),
      geofences: rows('geofences').map(FleetMapGeofence.fromJson).toList(),
      flights: rows('flights').map(FleetFlight.fromJson).toList(),
    );
  }

  final List<FleetMapHub> hubs;
  final List<FleetMapGeofence> geofences;
  final List<FleetFlight> flights;
}

/// Un incidente en vuelo (`hub-incident`, RF-34): dónde bajó el dron, qué
/// protocolo siguió y hasta cuándo hay para rescatarlo. Sin medicamento.
class FleetIncident {
  const FleetIncident({
    required this.id,
    required this.droneId,
    required this.protocol,
    required this.outcome,
    this.latitude,
    this.longitude,
    this.rescueDueAt,
    this.resolvedAt,
  });

  factory FleetIncident.fromJson(Map<String, dynamic> json) {
    double? coord(String key) => (json[key] as num?)?.toDouble();
    return FleetIncident(
      id: '${json['id']}',
      droneId: '${json['droneId']}',
      protocol: '${json['protocol']}',
      outcome: '${json['outcome']}',
      latitude: coord('landingLatitude') ?? coord('latitude'),
      longitude: coord('landingLongitude') ?? coord('longitude'),
      rescueDueAt: DateTime.tryParse('${json['rescueDueAt']}'),
      resolvedAt: DateTime.tryParse('${json['resolvedAt']}'),
    );
  }

  final String id;
  final String droneId;

  /// `continue`, `return_to_hub`, `emergency_landing`, `crash` o `lost`.
  final String protocol;

  /// `continued`, `returning`, `returned`, `landing`, `grounded`,
  /// `rescued` o `lost`.
  final String outcome;
  final double? latitude;
  final double? longitude;
  final DateTime? rescueDueAt;
  final DateTime? resolvedAt;

  bool get isOpen => resolvedAt == null;

  /// El protocolo en palabras.
  String get protocolLabel => switch (protocol) {
    'continue' => 'Sigue su ruta',
    'return_to_hub' => 'Vuelve a la central',
    'emergency_landing' => 'Aterrizaje de emergencia',
    'crash' => 'Choque',
    'lost' => 'Dron perdido',
    _ => 'Incidente en vuelo',
  };
}
