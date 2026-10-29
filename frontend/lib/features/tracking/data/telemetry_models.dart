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
  landed('landed', 'En tierra'),

  /// En destino, ya entregado: el dron espera un minuto a que retiren el
  /// medicamento y después vuelve vacío.
  unloading('unloading', 'Retiro del medicamento'),

  /// Una fase que esta versión de la app todavía no conoce: el mapa sigue.
  unknown('unknown', 'En vuelo');

  const FlightPhase(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// En tierra en el destino (esperando el código o el retiro).
  bool get onGround => this == landed || this == unloading;

  static FlightPhase fromJson(String value) {
    return FlightPhase.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => FlightPhase.unknown,
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

  /// Ya entregado, el dron espera en destino a que retiren el medicamento.
  bool get unloading => phase == FlightPhase.unloading;

  /// El dron vuelve a su central: con el paquete, o vacío tras entregar.
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

/// Tipo de alerta del vuelo; un tipo nuevo de Nest cae en [other].
enum FlightAlertKind {
  batteryCritical('battery_critical'),
  failure('failure'),
  coldChain('cold_chain'),
  other('other');

  const FlightAlertKind(this.apiValue);

  final String apiValue;

  static FlightAlertKind fromJson(Object? value) {
    return FlightAlertKind.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => FlightAlertKind.other,
    );
  }
}

/// Alerta del dron en vuelo. Le llega al operador de la central de origen
/// (siguiendo el pedido o en la sala de su central); el texto es el del
/// servidor.
class FlightAlert {
  const FlightAlert({
    required this.orderId,
    required this.message,
    this.droneId,
    this.kind = FlightAlertKind.other,
  });

  factory FlightAlert.fromJson(Map<String, dynamic> json) {
    return FlightAlert(
      orderId: json['orderId'] as String,
      message: json['message'] as String,
      droneId: json['droneId'] as String?,
      kind: FlightAlertKind.fromJson(json['kind']),
    );
  }

  final String orderId;
  final String message;
  final String? droneId;
  final FlightAlertKind kind;
}

/// Rango sano de la cadena de frío (RF-17).
const coldChainMinC = 2.0;
const coldChainMaxC = 8.0;

/// La temperatura salió de 2 a 8 °C.
bool isColdChainBreach(double? temperatureC) =>
    temperatureC != null &&
    (temperatureC < coldChainMinC || temperatureC > coldChainMaxC);

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse('$value');
  if (parsed == null) throw FormatException('Número inválido: $value');
  return parsed;
}
