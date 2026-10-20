/// Código de entrega (`POST /orders/:id/delivery-code`).
///
/// Nest lo genera cuando el dron ya aterrizó y solo guarda su hash: este es
/// el único momento en que se ve. Vence a los 5 minutos del aterrizaje
/// (CU-29); pedirlo otra vez reemplaza el anterior, con el mismo
/// vencimiento.
class DeliveryCode {
  const DeliveryCode({required this.code, required this.expiresAt});

  factory DeliveryCode.fromJson(Map<String, dynamic> json) {
    return DeliveryCode(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Seis dígitos.
  final String code;
  final DateTime expiresAt;

  /// Lo que falta para que venza; cero si ya venció.
  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}
