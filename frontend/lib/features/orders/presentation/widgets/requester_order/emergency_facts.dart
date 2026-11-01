import 'package:flutter/material.dart';

import '../../../../../theme/app_palette.dart';

/// Lo que se sabe antes de pedir, sobre el deslizador: la urgencia va
/// primero en la cola y la ruta evita las geovallas (reglas del sistema).
/// La llegada estimada se ve en el mapa cuando el dron despega.
class EmergencyFacts extends StatelessWidget {
  const EmergencyFacts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIORIDAD', style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  'Primero en la cola',
                  style: theme.textTheme.titleMedium?.copyWith(
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RUTA', style: theme.textTheme.labelSmall),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: palette.success),
                  const SizedBox(width: 4),
                  Text(
                    'Evita geovallas',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
