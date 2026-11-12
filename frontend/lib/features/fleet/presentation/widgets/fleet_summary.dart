import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/fleet_models.dart';

/// El resumen de la central arriba de la lista: cuántos drones están
/// disponibles, en vuelo y en taller, en una tarjeta partida en tres. Sale
/// de la misma lista de drones; no hay datos aparte.
class FleetSummary extends StatelessWidget {
  const FleetSummary({super.key, required this.drones});

  final List<Drone> drones;

  @override
  Widget build(BuildContext context) {
    int count(DroneStatus status) =>
        drones.where((d) => d.status == status).length;
    final line = Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    final cells = [
      ('Disponibles', count(DroneStatus.available), null),
      ('En vuelo', count(DroneStatus.inMission), PillTone.positive),
      ('En taller', count(DroneStatus.maintenance), PillTone.attention),
    ];
    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, (label, value, tone)) in cells.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: line),
              Expanded(
                child: _Cell(label: label, value: value, tone: tone),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.tone});

  final String label;
  final int value;

  /// Color de la cifra si es mayor que cero; sin tono, el del texto.
  final PillTone? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == null || value == 0
        ? null
        : StatusPill.colorOf(context, tone!);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(color: color),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
