import 'package:flutter/material.dart';

/// Lo que se sabe antes de pedir, en una nota gris sobre el deslizador:
/// la urgencia va primero en la cola, la central la elige el despachador
/// al autorizar y la ruta evita las geovallas (reglas del sistema). No
/// promete central ni tiempos: la llegada se ve en el mapa cuando el dron
/// despega.
class EmergencyFacts extends StatelessWidget {
  const EmergencyFacts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Va primero en la cola. Un despachador revisa tu pedido, elige '
              'la central y sale un Wingcopter 198 por una ruta que evita las '
              'geovallas. Te avisamos cuando despegue.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
