import 'package:flutter/material.dart';

import '../../../../../../core/widgets/status_pill.dart';
import '../../../../data/order_models.dart';
import 'decision_summary.dart';

/// Una central que miró el motor: el corredor, cuánto tarda, la batería
/// que pide el vuelo y el veredicto de cada dron con el motivo de Nest.
class HubTraceTile extends StatelessWidget {
  const HubTraceTile({super.key, required this.hub});

  final HubTrace hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final facts = hubTraceFacts(hub);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hub.name, style: theme.textTheme.titleSmall),
          if (facts.isNotEmpty) Text(facts, style: muted),
          if (hub.note case final note?) Text(note, style: muted),
          for (final drone in hub.drones) _DroneRow(drone: drone),
        ],
      ),
    );
  }
}

/// Un dron: su nombre, el veredicto en una pastilla y, si se descartó,
/// por qué.
class _DroneRow extends StatelessWidget {
  const _DroneRow({required this.drone});

  final DroneVerdict drone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final battery = drone.batteryPercent;
    final tone = switch (drone.status) {
      DroneVerdictStatus.chosen => PillTone.positive,
      DroneVerdictStatus.eligible => PillTone.neutral,
      DroneVerdictStatus.discarded => PillTone.negative,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              [
                drone.identifier,
                if (battery != null) '${battery.round()} %',
                ?drone.reason,
                if (drone.preempts) 'le quitó el dron a un programado',
              ].join(' · '),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: drone.status.label, tone: tone),
        ],
      ),
    );
  }
}
