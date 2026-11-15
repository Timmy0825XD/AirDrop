import 'package:flutter/material.dart';

import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../core/widgets/glass_card.dart';

/// El inicio de quien todavía no ha pedido nada: la ruta del corredor, qué
/// va a pasar y el botón para pedir la primera urgencia. Reemplaza a los
/// números, que aún no dicen nada.
class FirstOrderCard extends StatelessWidget {
  const FirstOrderCard({super.key, required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          children: [
            const CorridorArt(scene: CorridorScene.route),
            const SizedBox(height: 16),
            Text(
              'Pide tu primera urgencia',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'El dron sale de una central y llega a tu punto de entrega. '
              'Lo recibes con un código.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOrder,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Pedir urgencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
