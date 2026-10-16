class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;

  /// Código de negocio de Nest, por ejemplo `account_unverified`.
  final String? code;

  factory ApiException.fromNest(Object? data, {int? statusCode}) {
    if (data is Map<String, dynamic>) {
      final rawCode = data['code'];
      final code = rawCode is String && rawCode.trim().isNotEmpty
          ? rawCode.trim()
          : null;
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return ApiException(message.trim(), statusCode: statusCode, code: code);
      }
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        if (first is String && first.trim().isNotEmpty) {
          return ApiException(first.trim(), statusCode: statusCode, code: code);
        }
      }
    }
    return ApiException(_fallbackMessage(statusCode), statusCode: statusCode);
  }

  /// El texto para mostrar de cualquier error de un provider: el mensaje de
  /// Nest si lo hay; si no (un JSON raro, un fallo del cliente), uno
  /// genérico en vez de `FormatException: …`.
  static String messageOf(Object error) => error is ApiException
      ? error.message
      : 'No se pudo cargar la información. Intenta de nuevo.';

  factory ApiException.connection() =>
      const ApiException('No se pudo conectar con el servidor.');

  static String _fallbackMessage(int? statusCode) {
    return switch (statusCode) {
      401 => 'Tu sesión expiró. Inicia sesión de nuevo.',
      403 => 'No tienes permiso para hacer esto.',
      429 => 'Demasiados intentos. Espera un momento e intenta de nuevo.',
      _ => 'Algo salió mal. Intenta de nuevo.',
    };
  }

  @override
  String toString() => message;
}
