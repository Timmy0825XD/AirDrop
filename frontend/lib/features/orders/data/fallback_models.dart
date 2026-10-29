/// RF-18, HU-24 y CU-31: qué pasó cuando ningún dron de la central pudo
/// salir. Contrato en `backend/src/orders/order.presenter.ts`
/// (`presentFallback`) y `backend/src/decision/fallback.rules.ts`.
library;

/// `hub`: el pedido pasó a otra central. `conventional`: ninguna central
/// puede enviarlo por dron (final). `retry`: un programado espera dron y
/// Nest lo reintenta solo.
enum FallbackKind {
  hub('hub'),
  conventional('conventional'),
  retry('retry');

  const FallbackKind(this.apiValue);

  final String apiValue;

  static FallbackKind? fromJson(Object? value) {
    for (final kind in FallbackKind.values) {
      if (kind.apiValue == value) return kind;
    }
    return null;
  }
}

/// Una central que puede atender el pedido: la nueva (con `hub`) o una de
/// las alternativas para el traslado convencional.
class FallbackOption {
  const FallbackOption({
    required this.hubId,
    required this.name,
    required this.address,
    required this.contactPhone,
    this.contactEmail,
    this.distanceKm,
  });

  factory FallbackOption.fromJson(Map<String, dynamic> json) {
    final distance = json['distanceKm'];
    return FallbackOption(
      hubId: json['hubId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String?,
      distanceKm: distance is num
          ? distance.toDouble()
          : double.tryParse('$distance'),
    );
  }

  final String hubId;
  final String name;
  final String address;
  final String contactPhone;
  final String? contactEmail;
  final double? distanceKm;
}

/// La alternativa que ve quien pidió y quien despacha, mientras aplica.
class OrderFallback {
  const OrderFallback({
    required this.kind,
    this.reason,
    this.options = const [],
    this.retryAfter,
    this.reassignedAt,
  });

  /// `null` si no viene la clave, es `null` o trae un `kind` desconocido.
  static OrderFallback? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final kind = FallbackKind.fromJson(json['kind']);
    if (kind == null) return null;
    final raw = json['options'];
    return OrderFallback(
      kind: kind,
      reason: json['reason'] as String?,
      options: [
        if (raw is List)
          for (final item in raw.whereType<Map<String, dynamic>>())
            FallbackOption.fromJson(item),
      ],
      retryAfter: DateTime.tryParse('${json['retryAfter']}'),
      reassignedAt: DateTime.tryParse('${json['reassignedAt']}'),
    );
  }

  final FallbackKind kind;

  /// Por qué no salió un dron, en español del servidor.
  final String? reason;
  final List<FallbackOption> options;

  /// Próximo intento automático (`retry`).
  final DateTime? retryAfter;
  final DateTime? reassignedAt;

  /// La central que lo atiende ahora (`hub`), si viene.
  FallbackOption? get newHub =>
      kind == FallbackKind.hub && options.isNotEmpty ? options.first : null;
}

/// Qué pasó con un paquete devuelto tras revisarlo (HU-34).
enum ReturnOutcome {
  restocked('restocked', 'Volvió al inventario'),
  quarantined('quarantined', 'En cuarentena');

  const ReturnOutcome(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReturnOutcome? fromJson(Object? value) {
    for (final outcome in ReturnOutcome.values) {
      if (outcome.apiValue == value) return outcome;
    }
    return null;
  }
}
