import 'package:flutter/material.dart';

import '../../../../../core/widgets/bar_spark.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';

/// "1 de batería · 2 de frío": los incidentes del periodo por tipo.
String incidentBreakdown(IncidentCounts c) {
  final parts = [
    if (c.battery > 0) '${c.battery} de batería',
    if (c.failure > 0) '${c.failure} de falla',
    if (c.coldChain > 0) '${c.coldChain} de frío',
    if (c.returnedWithPackage > 0)
      '${c.returnedWithPackage} volvió con el paquete',
  ];
  return parts.isEmpty ? 'Sin incidentes en el periodo.' : parts.join(' · ');
}

/// Incidentes del periodo: por tipo, por día en barras y los drones con
/// más (hasta tres).
class FleetIncidentsCard extends StatelessWidget {
  const FleetIncidentsCard({super.key, required this.dashboard});

  final FleetDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byDay = dashboard.incidentsByDay;
    final drones = [...dashboard.incidentsByDrone]
      ..sort((a, b) => b.total.compareTo(a.total));
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INCIDENTES', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Text(
            incidentBreakdown(dashboard.incidents),
            style: theme.textTheme.bodyMedium,
          ),
          if (byDay.any((d) => d.total > 0)) ...[
            const SizedBox(height: 12),
            BarSpark(height: 48, values: [for (final d in byDay) d.total]),
          ],
          for (final d in drones.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${d.label} · ${incidentBreakdown(d)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
