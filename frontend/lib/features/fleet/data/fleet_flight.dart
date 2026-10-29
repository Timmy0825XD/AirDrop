import '../../orders/data/order_models.dart' show OrderStatus;
import '../../tracking/data/telemetry_models.dart' show FlightPhase;

/// Un dron en misión con su pedido, como lo da `GET /fleet/flights`
/// (`FleetFlightsService`, solo el operador). Con [orderId] el operador abre
/// el mapa del vuelo (`/tracking/:orderId`). La telemetría puede faltar
/// (`null`) si el vuelo todavía no arrancó.
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
    this.etaSeconds,
    this.batteryAlert = false,
    this.failureAlert = false,
    this.coldChainAlert = false,
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
      batteryPercent: (json['batteryPercent'] as num?)?.toDouble(),
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      batteryAlert: alertMap['battery'] == true,
      failureAlert: alertMap['failure'] == true,
      coldChainAlert: alertMap['coldChain'] == true,
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
  final int? etaSeconds;
  final bool batteryAlert;
  final bool failureAlert;
  final bool coldChainAlert;

  bool get hasAlert => batteryAlert || failureAlert || coldChainAlert;
}
