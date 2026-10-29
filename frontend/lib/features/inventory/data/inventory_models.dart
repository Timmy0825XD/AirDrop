/// Modelos de inventario de la central.
///
/// El contrato lo define `InventoryService.toPublicItem` en Nest: `id`,
/// `hubId`, `name`, `quantity`, `lot`, `expirationDate`,
/// `requiresColdChain`, `saleType` y `createdAt`.
///
/// Los body de alta y edición **no** llevan `hubId`: la central la resuelve
/// Nest desde la asignación del despachador (`InventoryService.requireDispatcherHub`).
library;

/// Los tres valores que acepta `CreateInventoryItemDto` (`SaleType` en Nest).
enum SaleType {
  overTheCounter('over_the_counter', 'Venta libre'),
  prescription('prescription', 'Bajo fórmula'),
  specialControl('special_control', 'Control especial');

  const SaleType(this.apiValue, this.label);

  final String apiValue;

  /// Etiqueta que muestra la UI. El mensaje de Nest es
  /// "El tipo de venta debe ser libre, bajo fórmula o control especial.".
  final String label;

  static SaleType fromJson(String value) {
    return SaleType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => throw FormatException('Tipo de venta desconocido: $value'),
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.hubId,
    required this.name,
    required this.quantity,
    required this.lot,
    required this.expirationDate,
    required this.requiresColdChain,
    required this.saleType,
    this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      hubId: json['hubId'] as String,
      name: json['name'] as String,
      quantity: _asInt(json['quantity']),
      lot: json['lot'] as String,
      expirationDate: json['expirationDate'] as String,
      requiresColdChain: json['requiresColdChain'] as bool,
      saleType: SaleType.fromJson(json['saleType'] as String),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  final String id;
  final String hubId;
  final String name;
  final int quantity;
  final String lot;

  /// Postgres `date`: viaja como `AAAA-MM-DD` y así se muestra y se edita.
  /// No se convierte a `DateTime` porque no tiene zona horaria.
  final String expirationDate;

  final bool requiresColdChain;
  final SaleType saleType;
  final DateTime? createdAt;
}

/// Body de `POST /inventory`. Sin `hubId`, que Nest toma de la asignación
/// del despachador.
class CreateInventoryItemRequest {
  const CreateInventoryItemRequest({
    required this.name,
    required this.quantity,
    required this.lot,
    required this.expirationDate,
    required this.requiresColdChain,
    required this.saleType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'lot': lot,
      'expirationDate': expirationDate,
      'requiresColdChain': requiresColdChain,
      'saleType': saleType.apiValue,
    };
  }

  final String name;
  final int quantity;
  final String lot;
  final String expirationDate;
  final bool requiresColdChain;
  final SaleType saleType;
}

/// Body de `PATCH /inventory/:id`. Todos los campos son opcionales y Nest
/// responde `Debes enviar al menos un campo para actualizar.` con un cuerpo
/// vacío: por eso [toJson] solo incluye los que cambiaron y la pantalla
/// revisa [isEmpty] antes de enviar.
class UpdateInventoryItemRequest {
  const UpdateInventoryItemRequest({
    this.name,
    this.quantity,
    this.lot,
    this.expirationDate,
    this.requiresColdChain,
    this.saleType,
  });

  bool get isEmpty =>
      name == null &&
      quantity == null &&
      lot == null &&
      expirationDate == null &&
      requiresColdChain == null &&
      saleType == null;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (lot != null) 'lot': lot,
      if (expirationDate != null) 'expirationDate': expirationDate,
      if (requiresColdChain != null) 'requiresColdChain': requiresColdChain,
      if (saleType != null) 'saleType': saleType!.apiValue,
    };
  }

  final String? name;
  final int? quantity;
  final String? lot;
  final String? expirationDate;
  final bool? requiresColdChain;
  final SaleType? saleType;
}

/// Postgres `numeric`/`int` puede serializarse como número o como texto;
/// se tolera ambos para que un cambio de serialización no rompa la lista.
int _asInt(Object? value) {
  if (value is int) return value;
  final parsed = int.tryParse('${value ?? ''}');
  if (parsed == null) {
    throw FormatException('Cantidad no entera: $value');
  }
  return parsed;
}

/// Por qué un insumo devuelto no reingresa (productos.md). Un motivo nuevo
/// de Nest cae en [other].
enum QuarantineReason {
  coldChain('cold_chain', 'Cadena de frío'),
  packaging('packaging', 'Empaque dañado'),
  other('other', 'Revisión');

  const QuarantineReason(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static QuarantineReason fromJson(Object? value) {
    return QuarantineReason.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => QuarantineReason.other,
    );
  }
}

/// Fila de `GET /inventory/quarantine`: un lote devuelto que no volvió al
/// stock (HU-34).
class QuarantineRecord {
  const QuarantineRecord({
    required this.id,
    required this.orderId,
    required this.medicationName,
    required this.saleType,
    required this.lot,
    required this.expirationDate,
    required this.quantity,
    required this.reason,
    this.createdAt,
  });

  factory QuarantineRecord.fromJson(Map<String, dynamic> json) {
    return QuarantineRecord(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      medicationName: json['medicationName'] as String? ?? '',
      saleType: SaleType.fromJson(json['saleType'] as String),
      lot: json['lot'] as String? ?? '',
      expirationDate: json['expirationDate'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reason: QuarantineReason.fromJson(json['reason']),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  final String id;
  final String orderId;
  final String medicationName;
  final SaleType saleType;
  final String lot;
  final String expirationDate;
  final int quantity;
  final QuarantineReason reason;
  final DateTime? createdAt;
}
