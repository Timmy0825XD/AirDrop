/// Código de entrega (`GET /orders/:id/delivery-code`).
///
/// Existe desde que el despachador de origen confirma la carga y es siempre
/// el mismo para el pedido. [expiresAt] llega `null` mientras el dron vuela;
/// cuando aterriza trae la hora límite (aterrizaje + 5 minutos, CU-29).
class DeliveryCode {
  const DeliveryCode({required this.code, this.expiresAt});

  factory DeliveryCode.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresAt'] as String?;
    return DeliveryCode(
      code: json['code'] as String,
      expiresAt: expires == null ? null : DateTime.parse(expires),
    );
  }

  /// Seis dígitos.
  final String code;
  final DateTime? expiresAt;

  /// El dron ya aterrizó y corre la espera.
  bool get landed => expiresAt != null;

  /// Lo que falta para que venza; `null` mientras el dron vuela y cero si
  /// ya venció.
  Duration? remaining(DateTime now) {
    final limit = expiresAt;
    if (limit == null) return null;
    final left = limit.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}
