import 'package:flutter/material.dart';
import '../../../../core/date_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/drone_glyph.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_icons.dart';
import '../../data/fleet_models.dart';
import 'drone_health.dart';
import 'drone_status_chip.dart';

class DroneTile extends StatelessWidget {
  const DroneTile({
    super.key,
    required this.drone,
    required this.modelName,
    required this.onActions,
    this.onFlight,
  });
  final Drone drone;
  final String? modelName;
  final VoidCallback? onActions, onFlight;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DroneHeading(drone: drone, modelName: modelName),
        const SizedBox(height: 10),
        _DroneDetails(drone: drone),
        DroneHealth(drone: drone),
        const SizedBox(height: 10),
        const Divider(height: 1),
        _DroneAction(drone: drone, onActions: onActions, onFlight: onFlight),
      ],
    ),
  );
}

class _DroneHeading extends StatelessWidget {
  const _DroneHeading({required this.drone, required this.modelName});
  final Drone drone;
  final String? modelName;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DroneGlyph(color: Theme.of(context).colorScheme.onSurface, size: 28),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 6,
              children: [
                Text(
                  drone.identifier,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _DroneState(status: drone.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              modelName ?? 'Modelo no disponible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DroneState extends StatelessWidget {
  const _DroneState({required this.status});
  final DroneStatus status;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = status == DroneStatus.inMission
        ? colors.primary
        : status == DroneStatus.maintenance
        ? colors.secondary
        : StatusPill.colorOf(context, DroneStatusChip.toneOf(status));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            status.label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _DroneDetails extends StatelessWidget {
  const _DroneDetails({required this.drone});
  final Drone drone;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final text in [
        if (drone.phase case final phase?) phase.label,
        if (drone.maintenanceReason case final reason?
            when reason.trim().isNotEmpty)
          reason,
        if (drone.maintenanceUntil case final date? when date.isNotEmpty)
          'Fecha estimada · ${formatDay(date, relative: false)}',
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
    ],
  );
}

class _DroneAction extends StatelessWidget {
  const _DroneAction({
    required this.drone,
    required this.onActions,
    required this.onFlight,
  });
  final Drone drone;
  final VoidCallback? onActions, onFlight;
  @override
  Widget build(BuildContext context) {
    final action = drone.status.isInMission ? onFlight : onActions;
    if (action == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          drone.status == DroneStatus.grounded
              ? 'Espera rescate'
              : drone.status.isInMission
              ? 'En vuelo'
              : 'Sin cambios',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return TextButton(
      onPressed: action,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 44),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(drone.status.isInMission ? 'Ver vuelo' : 'Gestionar'),
          ),
          const Icon(AppIcons.forward, size: 18),
        ],
      ),
    );
  }
}

String shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
