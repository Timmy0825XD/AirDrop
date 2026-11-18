import 'package:flutter/material.dart';

import '../../../../../core/widgets/route_line.dart';

/// Lo que se sabe antes de pedir, sobre el deslizador: la ruta que va a
/// recorrer el pedido (de una central a tu ubicación) y quién decide.
/// La urgencia va primero en la cola y la autoriza un despachador. No
/// promete central, dron ni tiempos: eso lo decide el sistema al autorizar
/// y la llegada se ve en el mapa cuando el dron despega.
class EmergencyFacts extends StatelessWidget {
  const EmergencyFacts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RouteLine(endLabel: 'Tu ubicación', hover: false),
          const SizedBox(height: 10),
          Text(
            'Va primero en la cola. Un despachador revisa tu pedido y '
            'autoriza la salida; el dron sigue una ruta que evita las zonas '
            'restringidas. Te avisamos cuando despegue.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
