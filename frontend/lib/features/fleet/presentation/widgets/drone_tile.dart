import 'package:flutter/material.dart';

import '../../data/fleet_models.dart';
import 'drone_status_chip.dart';

/// Fila del listado de flota: identificador, modelo, estado y, si vienen,
/// el motivo y la fecha del mantenimiento.
///
/// [onActions] es `null` cuando el dron está en misión: Nest responde
/// `409 No puedes cambiar el estado de un dron en misión.`, así que la
/// fila no ofrece ni cambiar estado ni registrar mantenimiento.
class DroneTile extends StatelessWidget {
  const DroneTile({
    super.key,
    required this.drone,
    required this.modelName,
    required this.onActions,
  });

  final Drone drone;
  final String? modelName;

  /// `null` deja la fila sin acciones (dron en misión).
  final VoidCallback? onActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onActions,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DroneTileHeader(
                      drone: drone,
                      modelName: modelName,
                    ),
                    if (drone.hasMaintenanceData) ...[
                      const SizedBox(height: 8),
                      _MaintenanceNote(drone: drone),
                    ],
                  ],
                ),
              ),
              if (onActions != null)
                IconButton(
                  tooltip: 'Gestionar estado',
                  onPressed: onActions,
                  icon: const Icon(Icons.tune),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Identificador, modelo y estado del dron.
class _DroneTileHeader extends StatelessWidget {
  const _DroneTileHeader({required this.drone, required this.modelName});

  final Drone drone;
  final String? modelName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(drone.identifier, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          modelName ?? 'Modelo no disponible',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [DroneStatusChip(status: drone.status)],
        ),
      ],
    );
  }
}

/// Motivo y fecha estimada del mantenimiento, solo si el dron los trae.
class _MaintenanceNote extends StatelessWidget {
  const _MaintenanceNote({required this.drone});

  final Drone drone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = drone.maintenanceReason?.trim();
    final hasReason = reason != null && reason.isNotEmpty;
    final hasDate = drone.maintenanceUntil?.isNotEmpty ?? false;
    if (!hasReason && !hasDate) return const SizedBox.shrink();

    return Text(
      [
        if (hasReason) 'Motivo: $reason',
        if (hasDate) 'Hasta ${drone.maintenanceUntil}',
      ].join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}
