import 'package:flutter/material.dart';

import '../../../../core/widgets/error_banner.dart';
import '../../../orders/data/order_models.dart' show OrderStatus;
import '../../data/telemetry_models.dart';
import '../../data/tracking_providers.dart';

/// El aviso del vuelo, en orden de importancia: el primero que aplique.
(String?, bool) _pickNotice(TrackingState s, bool showReturn) {
  if (s.problem != null) return (s.problem, true);
  if (s.alert != null) return (s.alert!.message, true);
  if (s.waitingForFlight) return ('El vuelo está por empezar.', false);
  // El estado del socket manda: llega antes que la foto siguiente.
  switch (s.status) {
    // Tras entregar el dron vuelve solo; el pedido sigue entregado.
    case OrderStatus.delivered:
      final t = s.telemetry;
      // Un minuto en destino para retirar el medicamento (fase unloading).
      if (t != null && t.unloading) {
        return (
          'Pedido entregado. Retira tu medicamento: el dron espera un '
              'minuto antes de volver.',
          false,
        );
      }
      if (!showReturn || t == null || !t.returning) {
        return ('Pedido entregado.', false);
      }
      return t.phase == FlightPhase.landed
          ? ('Pedido entregado. El dron ya volvió a su central.', false)
          : ('Pedido entregado. El dron vuelve a su central.', false);
    case OrderStatus.returned:
      return showReturn
          ? ('El dron volvió a la central con el paquete.', false)
          : ('El paquete volvió a la central.', false);
    case OrderStatus.returning:
      // Sin código a tiempo, intentos agotados o un traslado rechazado.
      return (
        'El pedido no se entregó. El dron vuelve a la central con el '
            'paquete.',
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

/// El aviso que corresponde arriba de la ficha, si hay alguno: problema,
/// alerta del dron, vuelo por empezar, entregado, de regreso con el paquete,
/// dron ya en destino o reconexión.
class FlightNotice extends StatelessWidget {
  const FlightNotice({super.key, required this.state, this.showReturn = true});

  final TrackingState state;

  /// `false` para el solicitante: no se le cuenta por dónde va el dron de
  /// regreso, solo qué pasó con su pedido.
  final bool showReturn;

  @override
  Widget build(BuildContext context) {
    final (message, isError) = _pickNotice(state, showReturn);
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
}
