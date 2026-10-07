/// Modelos del módulo de pedidos.
///
/// Contrato en `backend/src/orders/`: pedido público, plan público,
/// catálogo, cola y programados. `SaleType` se reutiliza de inventario;
/// no se copia.
library;

import 'dart:typed_data';

import '../../inventory/data/inventory_models.dart' show SaleType;
import '../../auth/data/auth_models.dart' show DocumentType;

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
  cancelled('cancelled', 'Cancelado');

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
      orElse: () =>
          throw FormatException('Estado de plan desconocido: $value'),
    );
  }
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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
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
    );
  }

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
}

/// Plan público, sin ocurrencias. `GET /orders/plans/:id` agrega la lista.
class DeliveryPlan {
  const DeliveryPlan({
    required this.id,
    required this.frequency,
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
  });

  factory DeliveryPlan.fromJson(Map<String, dynamic> json) {
    return DeliveryPlan(
      id: json['id'] as String,
      frequency: PlanFrequency.fromJson(json['frequency'] as String),
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
    );
  }

  final String id;
  final PlanFrequency frequency;
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
}

class PlanOccurrence {
  const PlanOccurrence({
    required this.id,
    required this.status,
    required this.scheduledFor,
    this.droneId,
  });

  factory PlanOccurrence.fromJson(Map<String, dynamic> json) {
    return PlanOccurrence(
      id: json['id'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      scheduledFor: json['scheduledFor'] as String,
      droneId: json['droneId'] as String?,
    );
  }

  final String id;
  final OrderStatus status;
  final String scheduledFor;
  final String? droneId;
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
  const ScheduledEntry({
    required this.order,
    required this.availableQuantity,
  });

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

/// Body de `POST /orders/plans`: como la urgencia más cantidad,
/// frecuencia y fecha de inicio. Sin `description`.
class CreatePlanRequest {
  const CreatePlanRequest({
    required this.medicationName,
    required this.saleType,
    required this.quantity,
    required this.frequency,
    required this.startDate,
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
      'quantity': quantity,
      'frequency': frequency.apiValue,
      'startDate': startDate,
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
  final PlanFrequency frequency;
  final String startDate;
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
    required this.frequency,
    required this.startDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'originHubId': originHubId,
      'medicationName': medicationName,
      'saleType': saleType.apiValue,
      'quantity': quantity,
      'frequency': frequency.apiValue,
      'startDate': startDate,
    };
  }

  final String originHubId;
  final String medicationName;
  final SaleType saleType;
  final int quantity;
  final PlanFrequency frequency;
  final String startDate;
}

int _asInt(Object? value) {
  if (value is int) return value;
  final parsed = int.tryParse('$value');
  if (parsed == null) throw FormatException('Cantidad no entera: $value');
  return parsed;
}

double? _asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
