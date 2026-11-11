/// El mapa en vivo del operador (§16, §17 y §18.1 de
/// `pendientes-backend.md`): `GET /fleet/map`, con los incidentes abiertos,
/// y `hub-incident`. De la central no
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
    this.incidents = const [],
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
      incidents: rows('incidents').map(FleetIncident.fromJson).toList(),
    );
  }

  final List<FleetMapHub> hubs;
  final List<FleetMapGeofence> geofences;
  final List<FleetFlight> flights;

  /// Los incidentes abiertos de sus centrales, el más reciente primero
  /// (§18.1).
  final List<FleetIncident> incidents;
}

/// Un incidente en vuelo (RF-34): llega en `incidents` de `GET /fleet/map`
/// (los abiertos, §18.1) y por `hub-incident` (§17). Qué le pasó al dron,
/// en qué tramo, qué protocolo siguió, dónde bajó y si llevaba el paquete.
/// Sin medicamento (RNF-05).
class FleetIncident {
  const FleetIncident({
    required this.id,
    required this.droneId,
    required this.protocol,
    required this.outcome,
    this.orderId = '',
    this.kind = '',
    this.major = false,
    this.leg = '',
    this.packageOnBoard = false,
    this.packageLost = false,
    this.batteryPercent,
    this.latitude,
    this.longitude,
    this.rescueDueAt,
    this.occurredAt,
    this.resolvedAt,
  });

  factory FleetIncident.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    return FleetIncident(
      id: '${json['id']}',
      orderId: json['orderId'] as String? ?? '',
      droneId: '${json['droneId']}',
      kind: json['kind'] as String? ?? '',
      major: json['severity'] == 'major',
      leg: json['leg'] as String? ?? '',
      protocol: '${json['protocol']}',
      outcome: '${json['outcome']}',
      packageOnBoard: json['packageOnBoard'] == true,
      packageLost: json['packageLost'] == true,
      batteryPercent: number('batteryPercent'),
      latitude: number('landingLatitude') ?? number('latitude'),
      longitude: number('landingLongitude') ?? number('longitude'),
      rescueDueAt: DateTime.tryParse('${json['rescueDueAt']}'),
      occurredAt: DateTime.tryParse('${json['occurredAt']}'),
      resolvedAt: DateTime.tryParse('${json['resolvedAt']}'),
    );
  }

  final String id;
  final String orderId;
  final String droneId;

  /// Uno de los 14 de `IncidentKind` (§17).
  final String kind;

  /// `severity: major`: el dron no sigue su misión.
  final bool major;

  /// `outbound` (ida) o `return` (regreso).
  final String leg;

  /// `continue`, `return_to_hub`, `emergency_landing`, `crash` o `lost`.
  final String protocol;

  /// `continued`, `returning`, `returned`, `landing`, `grounded`,
  /// `rescued` o `lost`.
  final String outcome;
  final bool packageOnBoard;

  /// Choque grave o dron perdido con el paquete a bordo.
  final bool packageLost;
  final double? batteryPercent;
  final double? latitude;
  final double? longitude;
  final DateTime? rescueDueAt;
  final DateTime? occurredAt;
  final DateTime? resolvedAt;

  bool get isOpen => resolvedAt == null;

  /// Qué le pasó, con los textos de la consola web.
  String get kindLabel => switch (kind) {
    'battery_critical' => 'Batería crítica',
    'wind_limit' => 'Viento sobre el límite',
    'route_blocked' => 'Ruta bloqueada por una geovalla',
    'battery_short' => 'La batería no alcanza la ruta nueva',
    'battery_degraded' => 'Batería degradada',
    'motor_failure' => 'Falla de 1 motor',
    'dual_motor_failure' => 'Falla de 2 motores',
    'gps_loss_minor' => 'GPS con falla',
    'gps_loss_major' => 'Sin GPS',
    'link_loss' => 'Pérdida de enlace',
    'cooling_failure' => 'Falla del frío',
    'collision_minor' => 'Choque leve',
    'collision_major' => 'Choque grave',
    'drone_lost' => 'Dron perdido',
    _ => 'Incidente en vuelo',
  };

  /// "en la ida" o "en el regreso".
  String? get legLabel => switch (leg) {
    'outbound' => 'en la ida',
    'return' => 'en el regreso',
    _ => null,
  };

  /// El protocolo en palabras.
  String get protocolLabel => switch (protocol) {
    'continue' => 'Sigue su ruta',
    'return_to_hub' => 'Vuelve a la central',
    'emergency_landing' => 'Aterrizaje de emergencia',
    'crash' => 'Choque',
    'lost' => 'Dron perdido',
    _ => 'Incidente en vuelo',
  };

  /// Cómo va: lo que el operador tiene que esperar.
  String get outcomeLabel => switch (outcome) {
    'continued' => 'Siguió su ruta',
    'returning' => 'Volviendo a la central',
    'returned' => 'Volvió a la central',
    'landing' => 'Aterrizando',
    'grounded' => 'En tierra, espera el rescate',
    'rescued' => 'Rescatado',
    'lost' => 'Sin rastro',
    _ => 'En curso',
  };

  /// "Paquete perdido", "Con el paquete a bordo" o "Sin paquete".
  String get packageLabel => packageLost
      ? 'Paquete perdido'
      : packageOnBoard
      ? 'Con el paquete a bordo'
      : 'Sin paquete';
}
