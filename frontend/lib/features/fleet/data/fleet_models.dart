/// Modelos de flota (`fleet`).
///
/// El contrato lo define `FleetService` en Nest: `toPublicModel` para los
/// modelos de dron y `toPublicDrone` para los drones.
///
/// Los modelos de dron **no** se crean desde la app: vienen sembrados en la
/// base (`DroneModelSeedService`, Wingcopter 198) y la pantalla solo los
/// lista para elegir uno en el alta.
library;

import '../../tracking/data/telemetry_models.dart' show FlightPhase;

/// Los cinco valores de `DroneStatus` en Nest, más [unknown].
///
/// [inMission] lo asigna el motor de decisión al autorizar un pedido; la
/// pantalla de flota nunca lo envía, porque `FleetService.assertNotInMission`
/// responde `409 No puedes cambiar el estado de un dron en misión.`
///
/// [grounded] lo pone el sistema (RF-34): el dron aterrizó de emergencia
/// fuera de su central y espera el rescate; al rescatarlo pasa solo a
/// `maintenance`. El operador no lo elige ni lo cambia.
enum DroneStatus {
  available('available', 'Disponible'),
  inMission('in_mission', 'En misión'),
  grounded('grounded', 'En tierra, espera rescate'),
  maintenance('maintenance', 'En mantenimiento'),
  outOfService('out_of_service', 'Fuera de servicio'),

  /// Un estado que Nest agregó y la app todavía no conoce: el dron se
  /// muestra sin acciones, en vez de tumbar la lista de la flota.
  unknown('unknown', 'Estado desconocido');

  const DroneStatus(this.apiValue, this.label);

  final String apiValue;

  /// Etiqueta que muestra la UI (RNF-15: español de Colombia).
  final String label;

  static DroneStatus fromJson(String value) {
    return DroneStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => DroneStatus.unknown,
    );
  }

  /// Los tres estados que acepta `UpdateDroneStatusDto`
  /// (`OPERATOR_DRONE_STATUSES` en Nest).
  static const List<DroneStatus> operatorStatuses = [
    available,
    maintenance,
    outOfService,
  ];

  /// Un dron en misión no admite cambio de estado ni mantenimiento.
  bool get isInMission => this == inMission;

  /// Si el operador puede cambiarle el estado: no en misión, no en tierra
  /// esperando el rescate (lo resuelve el sistema) ni en un estado que la
  /// app no conoce.
  bool get isOperable =>
      this != inMission && this != grounded && this != unknown;

  /// Fuera de la flota activa: en taller o en tierra esperando el rescate.
  bool get isOutOfFleet =>
      this == maintenance || this == outOfService || this == grounded;
}

/// Modelo de dron. `FleetService.toPublicModel`: `id`, `code`, `name`,
/// `maxSpeedKmh`, `maxPayloadKg` y `maxRangeKm`.
class DroneModel {
  const DroneModel({
    required this.id,
    required this.code,
    required this.name,
    required this.maxSpeedKmh,
    required this.maxPayloadKg,
    required this.maxRangeKm,
  });

  factory DroneModel.fromJson(Map<String, dynamic> json) {
    return DroneModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      maxSpeedKmh: _asDouble(json['maxSpeedKmh']),
      maxPayloadKg: _asDouble(json['maxPayloadKg']),
      maxRangeKm: _asDouble(json['maxRangeKm']),
    );
  }

  final String id;
  final String code;
  final String name;

  /// Postgres `numeric`; Nest lo serializa como número, pero se tolera
  /// texto para que un cambio de serialización no rompa la lista.
  final double maxSpeedKmh;
  final double maxPayloadKg;
  final double maxRangeKm;
}

/// Dron. `FleetService.toPublicDrone`: `id`, `identifier`,
/// `droneModelId`, `hubId`, `status`, `maintenanceReason`,
/// `maintenanceUntil` y `createdAt`; desde la rotación (§15) y el
/// mantenimiento (§16), la batería, el último vuelo y el contador de
/// revisión. El modelo viene **suelo**, sin el nombre: la UI lo resuelve
/// contra [DroneModel].
class Drone {
  const Drone({
    required this.id,
    required this.identifier,
    required this.droneModelId,
    required this.hubId,
    required this.status,
    this.maintenanceReason,
    this.maintenanceUntil,
    this.createdAt,
    this.activeOrderId,
    this.phase,
    this.batteryPercent,
    this.lastFlightEndedAt,
    this.flightsSinceMaintenance = 0,
    this.maintenanceCycles,
    this.maintenanceDue = false,
    this.maintenanceOverdue = false,
  });

  factory Drone.fromJson(Map<String, dynamic> json) {
    return Drone(
      id: json['id'] as String,
      identifier: json['identifier'] as String,
      droneModelId: json['droneModelId'] as String,
      hubId: json['hubId'] as String,
      status: DroneStatus.fromJson(json['status'] as String),
      maintenanceReason: json['maintenanceReason'] as String?,
      maintenanceUntil: json['maintenanceUntil'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      activeOrderId: json['activeOrderId'] as String?,
      phase: json['phase'] is String
          ? FlightPhase.fromJson(json['phase'] as String)
          : null,
      batteryPercent: _asDoubleOrNull(json['batteryPercent']),
      lastFlightEndedAt: DateTime.tryParse('${json['lastFlightEndedAt']}'),
      flightsSinceMaintenance:
          (json['flightsSinceMaintenance'] as num?)?.toInt() ?? 0,
      maintenanceCycles: (json['maintenanceCycles'] as num?)?.toInt(),
      maintenanceDue: json['maintenanceDue'] == true,
      maintenanceOverdue: json['maintenanceOverdue'] == true,
    );
  }

  final String id;
  final String identifier;
  final String droneModelId;
  final String hubId;
  final DroneStatus status;

  /// Batería ahora, con lo que recargó en tierra (§15); `null` si Nest no
  /// la manda (la vista del administrador o una versión vieja).
  final double? batteryPercent;

  /// Cuándo volvió de su último vuelo; `null` si nunca ha volado.
  final DateTime? lastFlightEndedAt;

  /// Vuelos desde la última revisión y cada cuántos toca (CU-17).
  final int flightsSinceMaintenance;
  final int? maintenanceCycles;

  /// Ya le toca revisión: sigue volando, pero hay que programarla.
  final bool maintenanceDue;

  /// Sigue en mantenimiento y la fecha estimada ya pasó (no se libera
  /// solo: lo libera el operador o mueve la fecha).
  final bool maintenanceOverdue;

  /// `null` cuando el dron nunca entró en mantenimiento.
  final String? maintenanceReason;

  /// Postgres `date`: viaja como `AAAA-MM-DD` y así se muestra y se edita.
  /// No se convierte a `DateTime` porque no tiene zona horaria.
  final String? maintenanceUntil;

  final DateTime? createdAt;

  /// El pedido que lleva (en misión); tras entregar, el regreso vacío
  /// sigue mostrando ese pedido.
  final String? activeOrderId;

  /// La fase del vuelo; `null` sin telemetría o en tierra.
  final FlightPhase? phase;

  /// Motivo y fecha solo se muestran si vienen y el dron no está
  /// disponible: al volver a `available`, Nest los limpia.
  bool get hasMaintenanceData =>
      (maintenanceReason != null && maintenanceReason!.trim().isNotEmpty) ||
      (maintenanceUntil != null && maintenanceUntil!.isNotEmpty);
}

/// Body de `POST /fleet/drones`. `hubId` **sí** viaja: a diferencia del
/// inventario, el operador puede tener varias centrales y Nest no puede
/// adivinar a cuál pertenece el dron.
class CreateDroneRequest {
  const CreateDroneRequest({
    required this.identifier,
    required this.droneModelId,
    required this.hubId,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'droneModelId': droneModelId,
      'hubId': hubId,
    };
  }

  final String identifier;
  final String droneModelId;
  final String hubId;
}

/// Body de `PATCH /fleet/drones/:id/status`. `in_mission` no es un valor
/// posible: solo los tres estados de [DroneStatus.operatorStatuses].
///
/// El motivo y la fecha son opcionales y, si no viajan, Nest **conserva**
/// los que ya tenía. Con [DroneStatus.available] los limpia, por eso no se
/// les manda motivo.
class UpdateDroneStatusRequest {
  const UpdateDroneStatusRequest({
    required this.status,
    this.reason,
    this.estimatedEndDate,
  });

  Map<String, dynamic> toJson() {
    final cleanedReason = reason?.trim();
    return {
      'status': status.apiValue,
      // Un motivo en blanco no se envía: Nest lo ignoraría igual
      // (`dto.reason?.trim() || actual`) y solo ensuciaría el cuerpo.
      if (cleanedReason != null && cleanedReason.isNotEmpty)
        'reason': cleanedReason,
      if (estimatedEndDate != null && estimatedEndDate!.isNotEmpty)
        'estimatedEndDate': estimatedEndDate,
    };
  }

  final DroneStatus status;
  final String? reason;

  /// `AAAA-MM-DD`, el formato que exige el regex del DTO.
  final String? estimatedEndDate;
}

/// Body de `POST /fleet/drones/:id/maintenance`. Aquí el motivo y la fecha
/// son **obligatorios** y el dron queda `maintenance` (temporal).
class RegisterMaintenanceRequest {
  const RegisterMaintenanceRequest({
    required this.reason,
    required this.estimatedEndDate,
  });

  Map<String, dynamic> toJson() {
    return {'reason': reason.trim(), 'estimatedEndDate': estimatedEndDate};
  }

  final String reason;
  final String estimatedEndDate;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse('${value ?? ''}');
  if (parsed == null) {
    throw FormatException('Valor numérico no válido: $value');
  }
  return parsed;
}

double? _asDoubleOrNull(Object? value) =>
    value == null ? null : double.tryParse('$value');

/// Los dos periodos de taller de `GET /fleet/drones/:id/maintenance`.
enum MaintenanceKind {
  maintenance('maintenance', 'Mantenimiento'),
  outOfService('out_of_service', 'Fuera de servicio');

  const MaintenanceKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Uno que la app no conozca se muestra como mantenimiento: la fila no
  /// debe tumbar el historial.
  static MaintenanceKind fromJson(Object? value) => MaintenanceKind.values
      .firstWhere((e) => e.apiValue == value, orElse: () => maintenance);
}

/// Un periodo del historial de taller (CU-17). Cada salida de la flota
/// abre uno y volver a disponible lo cierra; viene del más reciente al
/// más viejo.
class MaintenancePeriod {
  const MaintenancePeriod({
    required this.id,
    required this.kind,
    required this.reason,
    required this.flightsAtStart,
    required this.startedAt,
    this.estimatedEndDate,
    this.closedAt,
  });

  factory MaintenancePeriod.fromJson(Map<String, dynamic> json) {
    return MaintenancePeriod(
      id: json['id'] as String,
      kind: MaintenanceKind.fromJson(json['kind']),
      reason: json['reason'] as String? ?? '',
      flightsAtStart: (json['flightsAtStart'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.parse(json['startedAt'] as String),
      estimatedEndDate: json['estimatedEndDate'] as String?,
      closedAt: DateTime.tryParse('${json['closedAt']}'),
    );
  }

  final String id;
  final MaintenanceKind kind;
  final String reason;

  /// Cuántos vuelos llevaba desde la revisión anterior al entrar.
  final int flightsAtStart;
  final DateTime startedAt;

  /// `AAAA-MM-DD`; solo en mantenimiento.
  final String? estimatedEndDate;

  /// `null` mientras siga abierto.
  final DateTime? closedAt;

  bool get isOpen => closedAt == null;
}
