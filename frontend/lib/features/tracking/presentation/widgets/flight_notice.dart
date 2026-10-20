import 'package:flutter/material.dart';

import '../../../../core/widgets/error_banner.dart';
import '../../../orders/data/order_models.dart' show OrderStatus;
import '../../data/tracking_providers.dart';

/// El aviso que corresponde arriba de la ficha, si hay alguno: problema,
/// alerta del dron, vuelo por empezar, entregado, de regreso con el paquete,
/// dron ya en destino o reconexión.
class FlightNotice extends StatelessWidget {
  const FlightNotice({super.key, required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final (message, isError) = _pick(state);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.fastOutSlowIn,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.only(bottom: 12),
              child: ErrorBanner(message: message, success: !isError),
            ),
    );
  }

  /// En orden de importancia: el primero que aplique.
  static (String?, bool) _pick(TrackingState s) {
    if (s.problem != null) return (s.problem, true);
    if (s.alert != null) return (s.alert!.message, true);
    if (s.waitingForFlight) return ('El vuelo está por empezar.', false);
    // El estado del socket manda: llega antes que la foto siguiente.
    switch (s.status) {
      case OrderStatus.delivered:
        return ('Pedido entregado.', false);
      case OrderStatus.returned:
        return ('El dron volvió a la central con el paquete.', false);
      case OrderStatus.returning:
        return (
          'Nadie recibió el pedido a tiempo. El dron vuelve a la central con '
              'el paquete.',
          true,
        );
      default:
        break;
    }
    if (s.telemetry?.arrived ?? false) {
      return (
        'El dron llegó. Hay 5 minutos para recibirlo con el código.',
        false,
      );
    }
    if (!s.connected && s.telemetry != null) {
      return ('Reconectando con el vuelo…', true);
    }
    return (null, false);
  }
}
