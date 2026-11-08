import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';

/// Salud de la flota: con cuánta batería vuelven los drones y cuántos
/// piden revisión o tienen el mantenimiento vencido. Tocarla lleva a la
/// flota, donde se ve cuáles son.
class FleetHealthCard extends StatelessWidget {
  const FleetHealthCard({
    super.key,
    required this.dashboard,
    required this.onOpenFleet,
  });

  final FleetDashboard dashboard;
  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = dashboard.landingBatteryAverage;
    final min = dashboard.landingBatteryMin;
    final due = dashboard.maintenanceDue;
    final overdue = dashboard.maintenanceOverdue;
    return GlassCard(
      onTap: onOpenFleet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SALUD DE LA FLOTA', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Text(
            average == null
                ? 'Todavía no hay vuelos con la batería al volver.'
                : 'Vuelven con ${average.round()} % de batería en promedio'
                      '${min == null ? '' : ' · mínimo ${min.round()} %'}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(
                label: due == 1 ? '1 pide revisión' : '$due piden revisión',
                tone: due > 0 ? PillTone.attention : PillTone.positive,
              ),
              StatusPill(
                label: overdue == 1 ? '1 vencido' : '$overdue vencidos',
                tone: overdue > 0 ? PillTone.negative : PillTone.positive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
