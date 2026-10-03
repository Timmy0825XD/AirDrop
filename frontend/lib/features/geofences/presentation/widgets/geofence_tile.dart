import 'package:flutter/material.dart';

import '../../data/geofence_models.dart';

/// Fila del listado: nombre y motivo de la geovalla. Tocar abre la
/// edición; el ícono elimina con confirmación (la decide la pantalla).
class GeofenceTile extends StatelessWidget {
  const GeofenceTile({
    super.key,
    required this.geofence,
    required this.onTap,
    required this.onDelete,
  });

  final Geofence geofence;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(geofence.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(geofence.reason, style: mutedStyle),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                color: theme.colorScheme.error,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
