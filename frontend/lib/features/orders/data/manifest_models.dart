/// Manifiesto de carga (RF-47). Contrato en `backend/src/manifests/`
/// (`GET /orders/:id/manifest`). No lleva datos del paciente.
library;

/// Un renglón del manifiesto: qué va, de qué lote y cuánto.
class ManifestItem {
  const ManifestItem({
    required this.lot,
    required this.expiresOn,
    required this.quantity,
    this.medicationName,
  });

  factory ManifestItem.fromJson(Map<String, dynamic> json) => ManifestItem(
    medicationName: json['medicationName'] as String?,
    lot: json['lot'] as String? ?? '',
    expiresOn: json['expiresOn'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
  );

  final String? medicationName;
  final String lot;

  /// Postgres `date`: `AAAA-MM-DD`.
  final String expiresOn;
  final int quantity;
}

/// El manifiesto que se emite al confirmar la carga. Una carga nueva del
/// mismo pedido anula el anterior, que queda en [previous].
class CargoManifest {
  const CargoManifest({
    required this.number,
    required this.droneIdentifier,
    required this.originName,
    required this.destination,
    required this.items,
    required this.authorizedBy,
    this.issuedAt,
    this.payloadKg,
    this.coldCompartmentKg,
    this.coldRange,
    this.voidedAt,
    this.voidReason,
    this.previous = const [],
  });

  factory CargoManifest.fromJson(Map<String, dynamic> json) {
    final drone = json['drone'];
    final origin = json['origin'];
    final by = json['authorizedBy'];
    final items = json['items'];
    final previous = json['previous'];
    return CargoManifest(
      number: json['number'] as String? ?? '',
      issuedAt: DateTime.tryParse('${json['issuedAt']}'),
      droneIdentifier: drone is Map ? '${drone['identifier'] ?? ''}' : '',
      originName: origin is Map ? '${origin['name'] ?? ''}' : '',
      destination: json['destination'] as String? ?? '',
      items: [
        if (items is List)
          for (final row in items.whereType<Map<String, dynamic>>())
            ManifestItem.fromJson(row),
      ],
      payloadKg: _asDoubleOrNull(json['payloadKg']),
      coldCompartmentKg: _asDoubleOrNull(json['coldCompartmentKg']),
      coldRange: json['coldRange'] as String?,
      authorizedBy: by is Map ? '${by['name'] ?? ''}' : '',
      voidedAt: DateTime.tryParse('${json['voidedAt']}'),
      voidReason: json['voidReason'] as String?,
      previous: [
        if (previous is List)
          for (final row in previous.whereType<Map<String, dynamic>>())
            CargoManifest.fromJson(row),
      ],
    );
  }

  /// `MAN-2026-000001`: consecutivo por año.
  final String number;
  final DateTime? issuedAt;

  /// La matrícula del dron (`AD-NOR-01`).
  final String droneIdentifier;
  final String originName;

  /// La ubicación del solicitante o la central de destino.
  final String destination;
  final List<ManifestItem> items;

  /// Solo se muestran: no se calcula con ellos.
  final double? payloadKg;
  final double? coldCompartmentKg;

  /// "2–8 °C" si la carga va en frío.
  final String? coldRange;

  /// Quién confirmó la carga, o "Despachador automático".
  final String authorizedBy;
  final DateTime? voidedAt;
  final String? voidReason;

  /// Los manifiestos anulados del mismo pedido.
  final List<CargoManifest> previous;
}

double? _asDoubleOrNull(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
