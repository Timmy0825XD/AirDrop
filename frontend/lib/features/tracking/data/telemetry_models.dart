/// Modelos de la telemetría en vivo.
///
/// Contrato en `backend/src/telemetry/telemetry.rules.ts`: el mismo JSON
/// llega por `GET /telemetry/orders/:id` y por el evento `telemetry` del
/// socket. El solicitante recibe la vista `map`; el despachador u operador de
/// la central de origen, la vista `full`, que agrega batería, carga,
/// temperatura y latencia.
library;

import '../../orders/data/order_models.dart' show OrderStatus;

/// Fase del vuelo que publica el reloj de la simulación.
enum FlightPhase {
  takeoff('takeoff', 'Despegue'),
  transition('transition', 'Transición'),
  cruise('cruise', 'Crucero'),
  descent('descent', 'Descenso'),
  landing('landing', 'Aterrizaje'),
  landed('landed', 'En tierra');

  const FlightPhase(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FlightPhase fromJson(String value) {
    return FlightPhase.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Fase de vuelo desconocida: $value'),
    );
  }
}

/// Tramo del vuelo: la ida al destino o el regreso a la central con el
/// paquete, cuando nadie lo recibió a tiempo (CU-30).
enum FlightLeg {
  outbound('outbound'),
  back('return');

  const FlightLeg(this.apiValue);

  final String apiValue;

  /// Sin `leg` (versiones viejas de Nest) es la ida.
  static FlightLeg fromJson(Object? value) {
    return FlightLeg.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => FlightLeg.outbound,
    );
  }
}

/// Una foto del vuelo: dónde va el dron y cómo va.
class Telemetry {
  const Telemetry({
    required this.orderId,
    required this.droneId,
    required this.identifier,
    required this.latitude,
    required this.longitude,
    required this.altitudeM,
    required this.speedKmh,
    required this.phase,
    required this.status,
    this.leg = FlightLeg.outbound,
    this.etaSeconds,
    this.vitals,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      orderId: json['orderId'] as String,
      droneId: json['droneId'] as String,
      identifier: json['identifier'] as String,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      altitudeM: _asDouble(json['altitudeM']),
      speedKmh: _asDouble(json['speedKmh']),
      phase: FlightPhase.fromJson(json['phase'] as String),
      status: OrderStatus.fromJson(json['status'] as String),
      leg: FlightLeg.fromJson(json['leg']),
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      // Solo la vista `full` trae la batería.
      vitals: json.containsKey('batteryPercent')
          ? FlightVitals.fromJson(json)
          : null,
    );
  }

  final String orderId;
  final String droneId;

  /// Nombre corto del dron, como `D-01`.
  final String identifier;
  final double latitude;
  final double longitude;
  final double altitudeM;
  final double speedKmh;
  final FlightPhase phase;
  final OrderStatus status;
  final FlightLeg leg;

  /// `null` cuando ya está en tierra.
  final int? etaSeconds;

  /// Solo para el despachador u operador de origen (vista `full`).
  final FlightVitals? vitals;

  /// Minutos que faltan, redondeados hacia arriba; `null` en destino.
  int? get etaMinutes => etaSeconds == null ? null : (etaSeconds! / 60).ceil();

  /// El dron aterrizó en destino y el pedido espera el código (5 minutos).
  bool get arrived =>
      leg == FlightLeg.outbound &&
      phase == FlightPhase.landed &&
      status == OrderStatus.awaitingDelivery;

  /// El dron vuelve a la central con el paquete.
  bool get returning => leg == FlightLeg.back;
}

/// Lo que solo ve la central de origen.
class FlightVitals {
  const FlightVitals({
    required this.batteryPercent,
    required this.payloadKg,
    required this.latencyMs,
    this.temperatureC,
  });

  factory FlightVitals.fromJson(Map<String, dynamic> json) {
    return FlightVitals(
      batteryPercent: _asDouble(json['batteryPercent']),
      payloadKg: _asDouble(json['payloadKg']),
      latencyMs: _asDouble(json['latencyMs']),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
    );
  }

  final double batteryPercent;

  /// Cantidad × 0,5 kg.
  final double payloadKg;
  final double latencyMs;

  /// `null` si el pedido no exige cadena de frío.
  final double? temperatureC;
}

/// Alerta del dron en vuelo. Solo le llega al operador de la central de
/// origen; el texto es el del servidor.
class FlightAlert {
  const FlightAlert({required this.orderId, required this.message});

  factory FlightAlert.fromJson(Map<String, dynamic> json) {
    return FlightAlert(
      orderId: json['orderId'] as String,
      message: json['message'] as String,
    );
  }

  final String orderId;
  final String message;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse('$value');
  if (parsed == null) throw FormatException('Número inválido: $value');
  return parsed;
}
