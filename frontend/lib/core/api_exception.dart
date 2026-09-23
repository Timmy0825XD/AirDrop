class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  factory ApiException.fromNest(Object? data, {int? statusCode}) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return ApiException(message.trim(), statusCode: statusCode);
      }
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        if (first is String && first.trim().isNotEmpty) {
          return ApiException(first.trim(), statusCode: statusCode);
        }
      }
    }
    return ApiException(_fallbackMessage(statusCode), statusCode: statusCode);
  }

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
