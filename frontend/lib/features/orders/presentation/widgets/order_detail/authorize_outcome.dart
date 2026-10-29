import '../../../../../core/widgets/app_snack.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Sin dron: otra central, convencional o reintento.
AuthorizeOutcome _fallbackOutcome(Order order) {
  final fallback = order.fallback;
  return switch (fallback?.kind) {
    FallbackKind.hub => AuthorizeOutcome(
      message:
          'Ningún dron de tu central pudo salir. El pedido pasó a '
          '${fallback?.newHub?.name ?? 'otra central'}.',
      tone: SnackTone.warning,
      leavesHub: true,
    ),
    FallbackKind.conventional => const AuthorizeOutcome(
      message:
          'Ningún dron puede llevar este pedido. Queda como traslado '
          'convencional.',
      tone: SnackTone.warning,
      leavesHub: true,
    ),
    FallbackKind.retry => AuthorizeOutcome(
      message: fallback?.retryAfter == null
          ? 'Sin dron por ahora. Se reintenta solo.'
          : 'Sin dron por ahora. Se reintenta solo a las '
                '${formatClock(fallback!.retryAfter!)}.',
      tone: SnackTone.info,
      leavesHub: false,
    ),
    null => AuthorizeOutcome(
      message: order.statusReason ?? 'El pedido no quedó autorizado.',
      tone: SnackTone.warning,
      leavesHub: false,
    ),
  };
}

/// Lo que pasó al autorizar, para el aviso del despachador. Desde el
/// fallback (RF-18) `authorize` ya no responde 409 sin dron: responde el
/// pedido con `assignment` o con `fallback`.
class AuthorizeOutcome {
  const AuthorizeOutcome({
    required this.message,
    required this.tone,
    required this.leavesHub,
  });

  /// Lee el pedido que devolvió `POST /orders/:id/authorize`.
  factory AuthorizeOutcome.of(Order order) {
    if (order.assignment != null) {
      return const AuthorizeOutcome(
        message: 'Pedido autorizado. Falta confirmar la carga.',
        tone: SnackTone.success,
        leavesHub: false,
      );
    }
    // Destino dentro de una geovalla: Nest lo rechaza con su motivo.
    if (order.status == OrderStatus.rejected) {
      return AuthorizeOutcome(
        message: order.statusReason ?? 'El pedido quedó rechazado.',
        tone: SnackTone.error,
        leavesHub: true,
      );
    }
    return _fallbackOutcome(order);
  }

  final String message;
  final SnackTone tone;

  /// El pedido sale de la central (otra central, convencional o
  /// rechazado): la pantalla vuelve atrás.
  final bool leavesHub;
}
