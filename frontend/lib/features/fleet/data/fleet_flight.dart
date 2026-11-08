import '../../orders/data/order_models.dart' show OrderStatus;
import '../../tracking/data/telemetry_models.dart' show FlightPhase;

/// Un dron en misión con su pedido, como lo da `GET /fleet/flights` y
/// `GET /fleet/map` (`FleetFlightsService`, solo el operador). Con
/// [orderId] el operador abre el mapa del vuelo (`/tracking/:orderId`). La
/// telemetría puede faltar (`null`) si el vuelo todavía no arrancó. No trae
/// nada de quién recibe ni qué lleva (RNF-05).
class FleetFlight {
  const FleetFlight({
    required this.droneId,
    required this.identifier,
    required this.hubId,
    required this.orderId,
    required this.orderStatus,
    required this.requiresColdChain,
    this.phase,
    this.returning = false,
    this.batteryPercent,
    this.temperatureC,
    this.etaSeconds,
    this.batteryAlert = false,
    this.failureAlert = false,
    this.coldChainAlert = false,
    this.latitude,
    this.longitude,
    this.altitudeM,
    this.speedKmh,
    this.payloadKg,
    this.latencyMs,
    this.linkLost = false,
    this.route = const [],
    this.returnRoute = const [],
  });

  factory FleetFlight.fromJson(Map<String, dynamic> json) {
    final alerts = json['alerts'];
    final alertMap = alerts is Map ? alerts : const {};
    final phase = json['phase'];
    return FleetFlight(
      droneId: '${json['droneId']}',
      identifier: '${json['identifier']}',
      hubId: '${json['hubId']}',
      orderId: '${json['orderId']}',
      orderStatus: OrderStatus.fromJson('${json['orderStatus']}'),
      requiresColdChain: json['requiresColdChain'] == true,
      phase: phase is String ? FlightPhase.fromJson(phase) : null,
      returning: json['leg'] == 'return',
      batteryPercent: _num(json['batteryPercent']),
      temperatureC: _num(json['temperatureC']),
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      batteryAlert: alertMap['battery'] == true,
      failureAlert: alertMap['failure'] == true,
      coldChainAlert: alertMap['coldChain'] == true,
      latitude: _num(json['latitude']),
      longitude: _num(json['longitude']),
      altitudeM: _num(json['altitudeM']),
      speedKmh: _num(json['speedKmh']),
      payloadKg: _num(json['payloadKg']),
      latencyMs: _num(json['latencyMs']),
      linkLost: json['linkLost'] == true,
      route: _coordinates(json['route']),
      returnRoute: _coordinates(json['returnRoute']),
    );
  }

  final String droneId;
  final String identifier;
  final String hubId;
  final String orderId;
  final OrderStatus orderStatus;
  final bool requiresColdChain;
  final FlightPhase? phase;

  /// El tramo de regreso a la central (`leg: return`).
  final bool returning;
  final double? batteryPercent;

  /// Solo con cadena de frío; `null` si no hay telemetría.
  final double? temperatureC;
  final int? etaSeconds;
  final bool batteryAlert;
  final bool failureAlert;
  final bool coldChainAlert;

  /// Dónde va el dron; `null` sin telemetría.
  final double? latitude;
  final double? longitude;
  final double? altitudeM;
  final double? speedKmh;
  final double? payloadKg;
  final double? latencyMs;

  /// RF-34: sin enlace, la posición es estimada.
  final bool linkLost;

  /// El corredor de ida y el de regreso, `[longitud, latitud]`; el regreso
  /// llega vacío hasta que el dron empieza a volver.
  final List<List<double>> route;
  final List<List<double>> returnRoute;

  bool get hasAlert => batteryAlert || failureAlert || coldChainAlert;

  bool get hasPosition => latitude != null && longitude != null;

  /// La ruta que vuela ahora: la de regreso si ya vuelve y la trae.
  List<List<double>> get activeRoute =>
      returning && returnRoute.length >= 2 ? returnRoute : route;

  /// El vuelo con el último tick de `hub-telemetry` (el mapa se mueve sin
  /// volver a pedir `/fleet/map`).
  FleetFlight withTick(FleetTick tick) => FleetFlight(
    droneId: droneId,
    identifier: identifier,
    hubId: hubId,
    orderId: orderId,
    orderStatus: tick.status ?? orderStatus,
    requiresColdChain: requiresColdChain,
    phase: tick.phase ?? phase,
    returning: tick.returning,
    batteryPercent: tick.batteryPercent ?? batteryPercent,
    temperatureC: tick.temperatureC ?? temperatureC,
    etaSeconds: tick.etaSeconds,
    batteryAlert: batteryAlert,
    failureAlert: failureAlert,
    coldChainAlert: coldChainAlert,
    latitude: tick.latitude,
    longitude: tick.longitude,
    altitudeM: tick.altitudeM,
    speedKmh: tick.speedKmh,
    payloadKg: tick.payloadKg ?? payloadKg,
    latencyMs: tick.latencyMs ?? latencyMs,
    linkLost: tick.linkLost,
    route: route,
    returnRoute: returnRoute,
  );
}

/// Un tick de `hub-telemetry`: la vista completa de la aeronave, sin nada
/// del pedido.
class FleetTick {
  const FleetTick({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.altitudeM,
    required this.speedKmh,
    this.phase,
    this.status,
    this.returning = false,
    this.etaSeconds,
    this.batteryPercent,
    this.payloadKg,
    this.temperatureC,
    this.latencyMs,
    this.linkLost = false,
  });

  factory FleetTick.fromJson(Map<String, dynamic> json) {
    final phase = json['phase'];
    final status = json['status'];
    return FleetTick(
      orderId: '${json['orderId']}',
      latitude: _num(json['latitude']) ?? 0,
      longitude: _num(json['longitude']) ?? 0,
      altitudeM: _num(json['altitudeM']) ?? 0,
      speedKmh: _num(json['speedKmh']) ?? 0,
      phase: phase is String ? FlightPhase.fromJson(phase) : null,
      status: status is String ? OrderStatus.fromJson(status) : null,
      returning: json['leg'] == 'return',
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      batteryPercent: _num(json['batteryPercent']),
      payloadKg: _num(json['payloadKg']),
      temperatureC: _num(json['temperatureC']),
      latencyMs: _num(json['latencyMs']),
      linkLost: json['linkLost'] == true,
    );
  }

  final String orderId;
  final double latitude;
  final double longitude;
  final double altitudeM;
  final double speedKmh;
  final FlightPhase? phase;
  final OrderStatus? status;
  final bool returning;
  final int? etaSeconds;
  final double? batteryPercent;
  final double? payloadKg;
  final double? temperatureC;
  final double? latencyMs;
  final bool linkLost;
}

double? _num(Object? value) => value is num ? value.toDouble() : null;

/// `route.coordinates` de Nest (`{ altitudeM, distanceKm, coordinates }`).
List<List<double>> _coordinates(Object? route) {
  final raw = route is Map ? route['coordinates'] : null;
  if (raw is! List) return const [];
  return [
    for (final point in raw)
      if (point is List && point.length >= 2)
        [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
  ];
}
