import '../core/api_exception.dart';

/// Cuándo reintenta Riverpod un provider que falló.
///
/// Por defecto Riverpod 3 reintenta hasta 10 veces con espera creciente, y
/// mientras tanto la pantalla sigue cargando. Un error con código HTTP es
/// una respuesta de Nest (un 404 "El pedido no existe.", un 403), no una
/// caída: reintentarlo no cambia nada, así que se muestra de una vez. Solo
/// se reintenta, 3 veces, cuando no hubo respuesta del servidor.
Duration? retryOnlyWithoutResponse(int retryCount, Object error) {
  if (error is ApiException && error.statusCode != null) return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}
