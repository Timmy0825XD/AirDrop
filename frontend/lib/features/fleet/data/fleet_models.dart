/// Modelos de flota (`fleet`).
///
/// El contrato lo define `FleetService` en Nest: `toPublicModel` para los
/// modelos de dron y `toPublicDrone` para los drones.
///
/// Los modelos de dron **no** se crean desde la app: vienen sembrados en la
/// base (`DroneModelSeedService`, Wingcopter 198) y la pantalla solo los
/// lista para elegir uno en el alta.
library;

/// Los cuatro valores de `DroneStatus` en Nest.
///
/// [inMission] lo asigna el motor de decisión al autorizar un pedido; la
/// pantalla de flota nunca lo envía, porque `FleetService.assertNotInMission`
/// responde `409 No puedes cambiar el estado de un dron en misión.`
enum DroneStatus {
  available('available', 'Disponible'),
  inMission('in_mission', 'En misión'),
  maintenance('maintenance', 'En mantenimiento'),
  outOfService('out_of_service', 'Fuera de servicio');

  const DroneStatus(this.apiValue, this.label);

  final String apiValue;

  /// Etiqueta que muestra la UI (RNF-15: español de Colombia).
  final String label;

  static DroneStatus fromJson(String value) {
    return DroneStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => throw FormatException('Estado de dron desconocido: $value'),
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

  bool get isOperable => !isInMission;
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
/// `maintenanceUntil` y `createdAt`. El modelo viene **suelo**, sin el
/// nombre: la UI lo resuelve contra [DroneModel].
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
    );
  }

  final String id;
  final String identifier;
  final String droneModelId;
  final String hubId;
  final DroneStatus status;

  /// `null` cuando el dron nunca entró en mantenimiento.
  final String? maintenanceReason;

  /// Postgres `date`: viaja como `AAAA-MM-DD` y así se muestra y se edita.
  /// No se convierte a `DateTime` porque no tiene zona horaria.
  final String? maintenanceUntil;

  final DateTime? createdAt;

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
/// son **obligatorios** y el dron queda `out_of_service`.
class RegisterMaintenanceRequest {
  const RegisterMaintenanceRequest({
    required this.reason,
    required this.estimatedEndDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason.trim(),
      'estimatedEndDate': estimatedEndDate,
    };
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
