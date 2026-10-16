import 'package:flutter/material.dart';

import '../../../../core/widgets/error_banner.dart';
import '../../data/tracking_providers.dart';

/// El aviso que corresponde arriba de la ficha, si hay alguno: problema,
/// alerta del dron, vuelo por empezar, dron ya en destino o reconexión.
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
    if (s.telemetry?.arrived ?? false) {
      return ('El dron llegó. El pedido espera la entrega.', false);
    }
    if (!s.connected && s.telemetry != null) {
      return ('Reconectando con el vuelo…', true);
    }
    return (null, false);
  }
}
