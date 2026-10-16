import 'package:flutter/material.dart';

import '../../../../core/widgets/row_action_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../auth/presentation/widgets/drone_glyph.dart';
import '../../data/fleet_models.dart';
import 'drone_status_chip.dart';

/// Tarjeta de un dron: el dron dibujado, identificador, modelo y, si los
/// trae, motivo y fecha del mantenimiento; a la derecha el estado y
/// "Gestionar".
///
/// [onActions] es `null` cuando no se puede tocar: en misión (Nest
/// responde 409) o con la central suspendida (Nest responde 403). Ahí la
/// tarjeta dice por qué en vez del botón.
class DroneTile extends StatelessWidget {
  const DroneTile({
    super.key,
    required this.drone,
    required this.modelName,
    required this.onActions,
  });

  final Drone drone;
  final String? modelName;
  final VoidCallback? onActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = drone.status.isInMission;
    return StatusCard(
      leading: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (busy ? colors.secondary : colors.primary).withValues(
            alpha: 0.12,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: DroneGlyph(
          color: busy ? colors.secondary : colors.primary,
          size: 28,
        ),
      ),
      body: _DroneInfo(drone: drone, modelName: modelName),
      status: DroneStatusChip(status: drone.status),
      action: onActions == null
          ? Text(
              busy ? 'En vuelo' : 'Sin cambios',
              style: theme.textTheme.labelSmall,
            )
          : RowActionButton(label: 'Gestionar', onPressed: onActions!),
    );
  }
}

class _DroneInfo extends StatelessWidget {
  const _DroneInfo({required this.drone, required this.modelName});

  final Drone drone;
  final String? modelName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reason = drone.maintenanceReason?.trim();
    final until = drone.maintenanceUntil;
    final note = [
      if (reason != null && reason.isNotEmpty) 'Motivo: $reason',
      if (until != null && until.isNotEmpty) 'Hasta $until',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          drone.identifier,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          modelName ?? 'Modelo no disponible',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(note, style: muted),
        ],
      ],
    );
  }
}
