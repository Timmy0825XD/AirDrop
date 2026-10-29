/// Modelos del módulo de pedidos.
///
/// Contrato en `backend/src/orders/`: pedido público, plan público,
/// catálogo, cola y programados. `SaleType` se reutiliza de inventario;
/// no se copia.
library;

import 'dart:typed_data';

import '../../inventory/data/inventory_models.dart' show SaleType;
import '../../auth/data/auth_models.dart' show DocumentType;
import 'fallback_models.dart';
import 'plan_schedule_models.dart';

export 'fallback_models.dart';
export 'plan_schedule_models.dart';

enum MissionType {
  emergency('emergency', 'Urgencia'),
  scheduled('scheduled', 'Programado');

  const MissionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MissionType fromJson(String value) {
    return MissionType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Tipo de misión desconocido: $value'),
    );
  }
}

enum DestinationKind {
  person('person', 'Persona'),
  hub('hub', 'Central');

  const DestinationKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DestinationKind fromJson(String value) {
    return DestinationKind.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Destino desconocido: $value'),
    );
  }
}

enum OrderStatus {
  scheduled('scheduled', 'Agendado'),
  awaitingConfirmation('awaiting_confirmation', 'Por confirmar'),
  received('received', 'Recibido'),
  underReview('under_review', 'En revisión'),
  assigned('assigned', 'Asignado'),
  pendingLoad('pending_load', 'Pendiente de carga'),
  inFlight('in_flight', 'En vuelo'),
  awaitingDelivery('awaiting_delivery', 'En espera de entrega'),
  delivered('delivered', 'Entregado'),
  returning('returning', 'En retorno'),
  returned('returned', 'Devuelto'),
  rejected('rejected', 'Rechazado'),
  reassigned('reassigned', 'Reasignado'),
  cancelled('cancelled', 'Cancelado'),
  skipped('skipped', 'Omitido'),
  expired('expired', 'Vencido');

  const OrderStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OrderStatus fromJson(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Estado desconocido: $value'),
    );
  }
}

enum OrderPriority {
  high('high', 'Alta'),
  normal('normal', 'Normal');

  const OrderPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OrderPriority fromJson(String value) {
    return OrderPriority.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Prioridad desconocida: $value'),
    );
  }
}

enum PlanFrequency {
  once('once', 'Única'),
  weekly('weekly', 'Semanal'),
  biweekly('biweekly', 'Quincenal'),
  monthly('monthly', 'Mensual');

  const PlanFrequency(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PlanFrequency fromJson(String value) {
    return PlanFrequency.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Frecuencia desconocida: $value'),
    );
  }
}

enum PlanStatus {
  active('active', 'Activo'),
  cancelled('cancelled', 'Cancelado');

  const PlanStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PlanStatus fromJson(String value) {
    return PlanStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw FormatException('Estado de plan desconocido: $value'),
    );
  }
}

/// Lo que el motor de decisión reservó al autorizar: el dron y el corredor.
///
/// Viaja en `assignment` del pedido en `GET /orders/mine`, `GET /orders/:id`,
/// `GET /orders/pending-load`, `authorize` y `confirm-load`. En las altas,
/// la cola, los programados y el rechazo no viene la clave.
class OrderAssignment {
  const OrderAssignment({
    required this.droneId,
    required this.identifier,
    required this.modelName,
    required this.altitudeM,
    required this.distanceKm,
    required this.coordinates,
    this.returnCoordinates = const [],
    this.returnDistanceKm,
  });

  factory OrderAssignment.fromJson(Map<String, dynamic> json) {
    final route = json['route'] is Map ? json['route'] as Map : const {};
    final back = json['returnRoute'] is Map ? json['returnRoute'] as Map : null;
    return OrderAssignment(
      droneId: json['droneId'] as String,
      identifier: json['identifier'] as String,
      modelName: json['modelName'] as String,
      altitudeM: _asDoubleOrNull(route['altitudeM']) ?? 0,
      distanceKm: _asDoubleOrNull(route['distanceKm']) ?? 0,
      coordinates: _routePoints(route),
      returnCoordinates: back == null ? const [] : _routePoints(back),
      returnDistanceKm: back == null
          ? null
          : _asDoubleOrNull(back['distanceKm']),
    );
  }

  static List<List<double>> _routePoints(Map route) {
    final points = route['coordinates'] is List
        ? route['coordinates'] as List
        : const [];
    return [
      for (final point in points.whereType<List>())
        [for (final value in point) _asDoubleOrNull(value) ?? 0],
    ];
  }

  final String droneId;

  /// Nombre corto del dron en la central, como `D-01`.
  final String identifier;
  final String modelName;

  /// Altitud del corredor. Hoy siempre 100 m.
  final double altitudeM;
  final double distanceKm;

  /// Puntos del corredor como `[longitud, latitud]`, igual que GeoJSON.
  final List<List<double>> coordinates;

  /// Ruta de regreso (`assignment.returnRoute`), con las geovallas vigentes
  /// cuando el dron empezó a volver. Vacía hasta entonces.
  final List<List<double>> returnCoordinates;
  final double? returnDistanceKm;

  /// Ya hay una ruta de regreso que dibujar (2 puntos o más).
  bool get hasReturnRoute => returnCoordinates.length >= 2;
}

/// Pedido público: crear urgencia, `GET /orders/mine`, `GET /orders/:id`
/// y `POST /orders/:id/reject`. La cola y los programados agregan campos
/// en [QueueEntry] y [ScheduledEntry].
class Order {
  const Order({
    required this.id,
    required this.missionType,
    required this.destinationKind,
    required this.status,
    required this.priority,
    required this.medicationName,
    required this.saleType,
    required this.requiresColdChain,
    required this.quantity,
    required this.address,
    required this.hasPrescription,
    this.description,
    this.requesterId,
    required this.createdByUserId,
    this.destinationHubId,
    this.originHubId,
    this.latitude,
    this.longitude,
    this.droneId,
    this.statusReason,
    this.planId,
    this.scheduledFor,
    this.createdAt,
    this.loadConfirmedAt,
    this.assignment,
    this.coldChainAlert = false,
    this.coldChainAlertAt,
    this.authorizedAt,
    this.dispatchedLot,
    this.dispatchedLotExpiresOn,
    this.returnCheckedAt,
    this.returnOutcome,
    this.receiptRejectedReason,
    this.scheduledAt,
    this.windowEndsAt,
    this.confirmedAt,
    this.reassignedFromHubId,
    this.fallback,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final assignment = json['assignment'];
    return Order(
      id: json['id'] as String,
      missionType: MissionType.fromJson(json['missionType'] as String),
      destinationKind: DestinationKind.fromJson(
        json['destinationKind'] as String,
      ),
      status: OrderStatus.fromJson(json['status'] as String),
      priority: OrderPriority.fromJson(json['priority'] as String),
      medicationName: json['medicationName'] as String,
      saleType: SaleType.fromJson(json['saleType'] as String),
      requiresColdChain: json['requiresColdChain'] as bool,
      quantity: _asInt(json['quantity']),
      description: json['description'] as String?,
      requesterId: json['requesterId'] as String?,
      createdByUserId: json['createdByUserId'] as String,
      destinationHubId: json['destinationHubId'] as String?,
      originHubId: json['originHubId'] as String?,
      address: json['address'] as String,
      latitude: _asDoubleOrNull(json['latitude']),
      longitude: _asDoubleOrNull(json['longitude']),
      droneId: json['droneId'] as String?,
      statusReason: json['statusReason'] as String?,
      planId: json['planId'] as String?,
      scheduledFor: json['scheduledFor'] as String?,
      hasPrescription: json['hasPrescription'] as bool? ?? false,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      loadConfirmedAt: DateTime.tryParse('${json['loadConfirmedAt']}'),
      // Puede venir el objeto, `null` o no venir la clave: los dos últimos
      // significan "sin asignación".
      assignment: assignment is Map<String, dynamic>
          ? OrderAssignment.fromJson(assignment)
          : null,
      coldChainAlert: json['coldChainAlert'] as bool? ?? false,
      coldChainAlertAt: _dateOrNull(json['coldChainAlertAt']),
      authorizedAt: _dateOrNull(json['authorizedAt']),
      dispatchedLot: json['dispatchedLot'] as String?,
      dispatchedLotExpiresOn: json['dispatchedLotExpiresOn'] as String?,
      returnCheckedAt: _dateOrNull(json['returnCheckedAt']),
      returnOutcome: ReturnOutcome.fromJson(json['returnOutcome']),
      receiptRejectedReason: json['receiptRejectedReason'] as String?,
      scheduledAt: _dateOrNull(json['scheduledAt']),
      windowEndsAt: _dateOrNull(json['windowEndsAt']),
      confirmedAt: _dateOrNull(json['confirmedAt']),
      reassignedFromHubId: json['reassignedFromHubId'] as String?,
      fallback: OrderFallback.fromJson(json['fallback']),
    );
  }

  /// Copia con los campos que cambian al autorizar, confirmar, rechazar,
  /// revisar el retorno o cambiar una entrega. La usa el repositorio local
  /// para simular esas transiciones. [clearFallback] borra la alternativa
  /// (al autorizar con dron).
  Order copyWith({
    OrderStatus? status,
    String? statusReason,
    String? droneId,
    String? originHubId,
    DateTime? loadConfirmedAt,
    OrderAssignment? assignment,
    DateTime? returnCheckedAt,
    ReturnOutcome? returnOutcome,
    String? receiptRejectedReason,
    DateTime? scheduledAt,
    DateTime? windowEndsAt,
    DateTime? confirmedAt,
    String? scheduledFor,
    OrderFallback? fallback,
    String? reassignedFromHubId,
    bool clearFallback = false,
  }) {
    return Order(
      id: id,
      missionType: missionType,
      destinationKind: destinationKind,
      status: status ?? this.status,
      priority: priority,
      medicationName: medicationName,
      saleType: saleType,
      requiresColdChain: requiresColdChain,
      quantity: quantity,
      address: address,
      hasPrescription: hasPrescription,
      description: description,
      requesterId: requesterId,
      createdByUserId: createdByUserId,
      destinationHubId: destinationHubId,
      originHubId: originHubId ?? this.originHubId,
      latitude: latitude,
      longitude: longitude,
      droneId: droneId ?? this.droneId,
      statusReason: statusReason ?? this.statusReason,
      planId: planId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt,
      loadConfirmedAt: loadConfirmedAt ?? this.loadConfirmedAt,
      assignment: assignment ?? this.assignment,
      coldChainAlert: coldChainAlert,
      coldChainAlertAt: coldChainAlertAt,
      authorizedAt: authorizedAt,
      dispatchedLot: dispatchedLot,
      dispatchedLotExpiresOn: dispatchedLotExpiresOn,
      returnCheckedAt: returnCheckedAt ?? this.returnCheckedAt,
      returnOutcome: returnOutcome ?? this.returnOutcome,
      receiptRejectedReason:
          receiptRejectedReason ?? this.receiptRejectedReason,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      windowEndsAt: windowEndsAt ?? this.windowEndsAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      reassignedFromHubId: reassignedFromHubId ?? this.reassignedFromHubId,
      fallback: clearFallback ? null : (fallback ?? this.fallback),
    );
  }

  /// Autorizado, con dron reservado, y nadie ha confirmado la carga: el
  /// reloj de la simulación todavía no arranca.
  bool get awaitsLoad =>
      status == OrderStatus.pendingLoad && loadConfirmedAt == null;

  /// Quien recibe ya puede ver su código: desde que se confirma la carga
  /// hasta que el dron espera en destino.
  bool get deliveryCodeVisible =>
      status == OrderStatus.inFlight ||
      status == OrderStatus.awaitingDelivery ||
      (status == OrderStatus.pendingLoad && loadConfirmedAt != null);

  /// Ya hay (o está por haber) un vuelo que seguir en el mapa: carga
  /// confirmada, en vuelo, esperando la entrega en destino o volviendo con
  /// el paquete.
  bool get hasFlight =>
      status == OrderStatus.inFlight ||
      status == OrderStatus.awaitingDelivery ||
      status == OrderStatus.returning ||
      (status == OrderStatus.pendingLoad && loadConfirmedAt != null);

  final String id;
  final MissionType missionType;
  final DestinationKind destinationKind;
  final OrderStatus status;
  final OrderPriority priority;
  final String medicationName;
  final SaleType saleType;
  final bool requiresColdChain;
  final int quantity;
  final String? description;
  final String? requesterId;
  final String createdByUserId;
  final String? destinationHubId;
  final String? originHubId;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? droneId;
  final String? statusReason;
  final String? planId;

  /// Postgres `date`: viaja como `AAAA-MM-DD`, no se pasa por `DateTime`.
  final String? scheduledFor;
  final bool hasPrescription;

  /// `timestamptz`: se muestra en `America/Bogota`.
  final DateTime? createdAt;

  /// Cuándo el despachador confirmó la carga. Distingue "pendiente de carga"
  /// de "ya confirmé y el reloj acaba de arrancar" (el estado sigue en
  /// `pending_load` hasta el primer tick).
  final DateTime? loadConfirmedAt;

  /// Dron y corredor reservados al autorizar; `null` antes de eso.
  final OrderAssignment? assignment;

  /// La temperatura de la carga salió de 2 a 8 °C (RF-17). Un retorno con
  /// esta marca va a cuarentena aunque el empaque esté bien.
  final bool coldChainAlert;
  final DateTime? coldChainAlertAt;
  final DateTime? authorizedAt;

  /// Lote que salió al confirmar la carga y su vencimiento (AAAA-MM-DD).
  /// Solo para la central; no se le muestra al solicitante.
  final String? dispatchedLot;
  final String? dispatchedLotExpiresOn;

  /// Revisión del paquete devuelto (`return-check`) y su resultado.
  final DateTime? returnCheckedAt;
  final ReturnOutcome? returnOutcome;

  /// Por qué la central de destino rechazó el traslado (el dron vuelve con
  /// el paquete), en texto del servidor.
  final String? receiptRejectedReason;

  /// Franja de 1 hora de una entrega de plan con calendario.
  final DateTime? scheduledAt;
  final DateTime? windowEndsAt;

  /// Cuándo confirmó quien recibe.
  final DateTime? confirmedAt;

  /// La central que no pudo despacharlo (fallback `hub`).
  final String? reassignedFromHubId;

  /// Qué pasó cuando ningún dron pudo salir; `null` si no aplica.
  final OrderFallback? fallback;

  /// Volvió a la central y nadie ha revisado el paquete.
  bool get awaitsReturnCheck =>
      status == OrderStatus.returned && returnCheckedAt == null;

  /// Pasó a otra central y está vivo en su cola.
  bool get reassignedToHub =>
      status == OrderStatus.reassigned && fallback?.kind == FallbackKind.hub;
}

/// Plan público, sin ocurrencias. `GET /orders/plans/:id` agrega la lista.
class DeliveryPlan {
  const DeliveryPlan({
    required this.id,
    this.frequency,
    required this.status,
    required this.medicationName,
    required this.saleType,
    required this.requiresColdChain,
    required this.quantity,
    required this.startDate,
    required this.windowEndsOn,
    required this.destinationKind,
    required this.address,
    required this.hasPrescription,
    required this.renewalDue,
    this.originHubId,
    this.destinationHubId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.schedule,
    this.paused = false,
    this.windowMinutes,
    this.prescriptionValidUntil,
    this.busySlots = const [],
  });

  factory DeliveryPlan.fromJson(Map<String, dynamic> json) {
    final frequency = json['frequency'];
    final busy = json['busySlots'];
    return DeliveryPlan(
      id: json['id'] as String,
      // `null` en los planes con calendario (RU-30).
      frequency: frequency is String ? PlanFrequency.fromJson(frequency) : null,
      status: PlanStatus.fromJson(json['status'] as String),
      medicationName: json['medicationName'] as String,
      saleType: SaleType.fromJson(json['saleType'] as String),
      requiresColdChain: json['requiresColdChain'] as bool,
      quantity: _asInt(json['quantity']),
      startDate: json['startDate'] as String,
      windowEndsOn: json['windowEndsOn'] as String,
      destinationKind: DestinationKind.fromJson(
        json['destinationKind'] as String,
      ),
      address: json['address'] as String,
      hasPrescription: json['hasPrescription'] as bool? ?? false,
      renewalDue: json['renewalDue'] as bool? ?? false,
      originHubId: json['originHubId'] as String?,
      destinationHubId: json['destinationHubId'] as String?,
      latitude: _asDoubleOrNull(json['latitude']),
      longitude: _asDoubleOrNull(json['longitude']),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      schedule: PlanSchedule.fromJson(json['schedule']),
      paused: json['paused'] as bool? ?? false,
      windowMinutes: (json['windowMinutes'] as num?)?.toInt(),
      prescriptionValidUntil: json['prescriptionValidUntil'] as String?,
      busySlots: [
        if (busy is List)
          for (final row in busy.whereType<Map<String, dynamic>>())
            BusySlot.fromJson(row),
      ],
    );
  }

  /// Copia con lo que cambia al pausar o reanudar (repositorio local).
  DeliveryPlan copyWith({bool? paused, PlanStatus? status}) {
    return DeliveryPlan(
      id: id,
      frequency: frequency,
      status: status ?? this.status,
      medicationName: medicationName,
      saleType: saleType,
      requiresColdChain: requiresColdChain,
      quantity: quantity,
      startDate: startDate,
      windowEndsOn: windowEndsOn,
      destinationKind: destinationKind,
      address: address,
      hasPrescription: hasPrescription,
      renewalDue: renewalDue,
      originHubId: originHubId,
      destinationHubId: destinationHubId,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      schedule: schedule,
      paused: paused ?? this.paused,
      windowMinutes: windowMinutes,
      prescriptionValidUntil: prescriptionValidUntil,
      busySlots: busySlots,
    );
  }

  final String id;

  /// Planes viejos (8 semanas). `null` en los de calendario: esos no se
  /// extienden, se les cambia el calendario.
  final PlanFrequency? frequency;
  final PlanStatus status;
  final String medicationName;
  final SaleType saleType;
  final bool requiresColdChain;
  final int quantity;
  final String startDate;
  final String windowEndsOn;
  final DestinationKind destinationKind;
  final String address;
  final bool hasPrescription;
  final bool renewalDue;
  final String? originHubId;
  final String? destinationHubId;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  /// La regla de calendario (en los planes viejos, reconstruida).
  final PlanSchedule? schedule;
  final bool paused;

  /// `60` con franja de 1 hora; `null` en los planes viejos (todo el día).
  final int? windowMinutes;

  /// Hasta cuándo vale la fórmula (AAAA-MM-DD); el plan no pasa de ahí.
  final String? prescriptionValidUntil;

  /// Aviso al crear o cambiar el calendario con central de origen.
  final List<BusySlot> busySlots;

  /// Solo los planes con frecuencia se extienden.
  bool get canExtend => frequency != null;
}

class PlanOccurrence {
  const PlanOccurrence({
    required this.id,
    required this.status,
    required this.scheduledFor,
    this.droneId,
    this.scheduledAt,
    this.windowEndsAt,
  });

  factory PlanOccurrence.fromJson(Map<String, dynamic> json) {
    return PlanOccurrence(
      id: json['id'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      scheduledFor: json['scheduledFor'] as String,
      droneId: json['droneId'] as String?,
      scheduledAt: _dateOrNull(json['scheduledAt']),
      windowEndsAt: _dateOrNull(json['windowEndsAt']),
    );
  }

  final String id;
  final OrderStatus status;
  final String scheduledFor;
  final String? droneId;

  /// Franja de 1 hora; `null` en los planes viejos.
  final DateTime? scheduledAt;
  final DateTime? windowEndsAt;
}

class PlanDetail {
  const PlanDetail({required this.plan, required this.occurrences});

  factory PlanDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['occurrences'];
    final rows = raw is List ? raw : const [];
    return PlanDetail(
      plan: DeliveryPlan.fromJson(json),
      occurrences: rows
          .whereType<Map<String, dynamic>>()
          .map(PlanOccurrence.fromJson)
          .toList(growable: false),
    );
  }

  final DeliveryPlan plan;
  final List<PlanOccurrence> occurrences;
}

/// Fila del catálogo: nombre y `saleType` juntos son la unidad del
/// selector. `availableQuantity` es `null` sin `hubId`.
class CatalogOffer {
  const CatalogOffer({
    required this.name,
    required this.saleType,
    required this.requiresColdChain,
    this.availableQuantity,
  });

  factory CatalogOffer.fromJson(Map<String, dynamic> json) {
    final rawQty = json['availableQuantity'];
    return CatalogOffer(
      name: json['name'] as String,
      saleType: SaleType.fromJson(json['saleType'] as String),
      requiresColdChain: json['requiresColdChain'] as bool? ?? false,
      availableQuantity: rawQty == null ? null : _asInt(rawQty),
    );
  }

  final String name;
  final SaleType saleType;
  final bool requiresColdChain;
  final int? availableQuantity;
}

class OriginHub {
  const OriginHub({
    required this.id,
    required this.name,
    required this.address,
  });

  factory OriginHub.fromJson(Map<String, dynamic> json) {
    return OriginHub(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }

  final String id;
  final String name;
  final String address;
}

/// Fila de `GET /orders/queue`: pedido más stock y marca de 5 minutos.
class QueueEntry {
  const QueueEntry({
    required this.order,
    required this.availableQuantity,
    required this.unattended,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      order: Order.fromJson(json),
      availableQuantity: _asInt(json['availableQuantity']),
      unattended: json['unattended'] as bool? ?? false,
    );
  }

  final Order order;
  final int availableQuantity;
  final bool unattended;
}

/// Fila de `GET /orders/scheduled`: sin `unattended`.
class ScheduledEntry {
  const ScheduledEntry({required this.order, required this.availableQuantity});

  factory ScheduledEntry.fromJson(Map<String, dynamic> json) {
    return ScheduledEntry(
      order: Order.fromJson(json),
      availableQuantity: _asInt(json['availableQuantity']),
    );
  }

  final Order order;
  final int availableQuantity;
}

/// Imagen de la fórmula: bytes en memoria, nunca en disco ni en logs.
class PrescriptionFile {
  const PrescriptionFile({required this.bytes, required this.mime});

  final Uint8List bytes;
  final String mime;
}

/// Body de `POST /orders/emergencies`. Sin `quantity`: el servidor guarda 1.
class CreateEmergencyRequest {
  const CreateEmergencyRequest({
    required this.medicationName,
    required this.saleType,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.patientDocumentType,
    this.patientDocumentNumber,
    this.prescriptionMime,
    this.prescriptionImageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'saleType': saleType.apiValue,
      'description': description,
      'address': address,
      if (latitude != null && longitude != null) 'latitude': latitude,
      if (latitude != null && longitude != null) 'longitude': longitude,
      if (saleType == SaleType.prescription) ...{
        'patientDocumentType': patientDocumentType!.apiValue,
        'patientDocumentNumber': patientDocumentNumber,
        'prescriptionMime': prescriptionMime,
        'prescriptionImageBase64': prescriptionImageBase64,
      },
    };
  }

  final String medicationName;
  final SaleType saleType;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final DocumentType? patientDocumentType;
  final String? patientDocumentNumber;
  final String? prescriptionMime;
  final String? prescriptionImageBase64;
}

/// Body de `POST /orders/plans`: como la urgencia más cantidad y el
/// calendario ([schedule], RU-30). Los planes viejos mandaban [frequency] y
/// [startDate]; nunca van los dos modos en el mismo body. Sin
/// `description`.
class CreatePlanRequest {
  const CreatePlanRequest({
    required this.medicationName,
    required this.saleType,
    required this.quantity,
    required this.address,
    this.frequency,
    this.startDate,
    this.schedule,
    this.prescriptionValidUntil,
    this.latitude,
    this.longitude,
    this.patientDocumentType,
    this.patientDocumentNumber,
    this.prescriptionMime,
    this.prescriptionImageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'saleType': saleType.apiValue,
      'quantity': quantity,
      ..._timingJson(schedule, frequency, startDate),
      'prescriptionValidUntil': ?prescriptionValidUntil,
      'address': address,
      if (latitude != null && longitude != null) 'latitude': latitude,
      if (latitude != null && longitude != null) 'longitude': longitude,
      if (saleType == SaleType.prescription) ...{
        'patientDocumentType': patientDocumentType!.apiValue,
        'patientDocumentNumber': patientDocumentNumber,
        'prescriptionMime': prescriptionMime,
        'prescriptionImageBase64': prescriptionImageBase64,
      },
    };
  }

  final String medicationName;
  final SaleType saleType;
  final int quantity;
  final PlanFrequency? frequency;
  final String? startDate;
  final PlanSchedule? schedule;

  /// Obligatoria con fórmula: el plan no pasa de esa fecha.
  final String? prescriptionValidUntil;
  final String address;
  final double? latitude;
  final double? longitude;
  final DocumentType? patientDocumentType;
  final String? patientDocumentNumber;
  final String? prescriptionMime;
  final String? prescriptionImageBase64;
}

/// Body de `POST /orders/hub-emergencies`: sin dirección ni fórmula.
class CreateHubEmergencyRequest {
  const CreateHubEmergencyRequest({
    required this.originHubId,
    required this.medicationName,
    required this.saleType,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'originHubId': originHubId,
      'medicationName': medicationName,
      'saleType': saleType.apiValue,
      'quantity': quantity,
    };
  }

  final String originHubId;
  final String medicationName;
  final SaleType saleType;
  final int quantity;
}

/// Body de `POST /orders/hub-plans`.
class CreateHubPlanRequest {
  const CreateHubPlanRequest({
    required this.originHubId,
    required this.medicationName,
    required this.saleType,
    required this.quantity,
    this.frequency,
    this.startDate,
    this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'originHubId': originHubId,
      'medicationName': medicationName,
      'saleType': saleType.apiValue,
      'quantity': quantity,
      ..._timingJson(schedule, frequency, startDate),
    };
  }

  final String originHubId;
  final String medicationName;
  final SaleType saleType;
  final int quantity;
  final PlanFrequency? frequency;
  final String? startDate;
  final PlanSchedule? schedule;
}

/// El calendario o, en los planes viejos, frecuencia y fecha de inicio:
/// Nest valida `frequency` y `startDate` solo si no hay `schedule`.
Map<String, dynamic> _timingJson(
  PlanSchedule? schedule,
  PlanFrequency? frequency,
  String? startDate,
) {
  if (schedule != null) return {'schedule': schedule.toJson()};
  return {'frequency': ?frequency?.apiValue, 'startDate': ?startDate};
}

int _asInt(Object? value) {
  if (value is int) return value;
  final parsed = int.tryParse('$value');
  if (parsed == null) throw FormatException('Cantidad no entera: $value');
  return parsed;
}

DateTime? _dateOrNull(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');

double? _asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
