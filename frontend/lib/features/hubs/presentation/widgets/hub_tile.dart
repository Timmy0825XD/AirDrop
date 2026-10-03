import 'package:flutter/material.dart';

import '../../data/hub_models.dart';
import 'hub_labels.dart';
import 'hub_status_chip.dart';

/// Fila del listado de centrales: nombre, tipo, estado y teléfono, con la
/// acción de suspender o reactivar según el estado actual.
///
/// El botón nunca ofrece la acción que ya está aplicada: Nest responde 409
/// si se repite (`Esta central ya está suspendida.`).
class HubTile extends StatelessWidget {
  const HubTile({super.key, required this.hub, required this.onToggle});

  final Hub hub;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hub.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '${HubLabels.type(hub.type)} · ${hub.contactPhone}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HubStatusChip(status: hub.status),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onToggle,
                  child: Text(hub.isActive ? 'Suspender' : 'Activar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
