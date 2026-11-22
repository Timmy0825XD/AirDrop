import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';
import 'dashboard_period.dart';
import 'operator_dashboard_details.dart';

class OperatorPeriodSummary extends StatelessWidget {
  const OperatorPeriodSummary({
    super.key,
    required this.dashboard,
    required this.onOpenFleet,
  });
  final FleetDashboard dashboard;
  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        for (final (section, icon, title) in [
          (
            OperatorMetric.usage,
            AppIcons.flight,
            '${dashboard.flights} vuelos · ${decimal(dashboard.km)} km',
          ),
          (OperatorMetric.health, AppIcons.health, 'Salud de la flota'),
          (
            OperatorMetric.incidents,
            AppIcons.warning,
            'Incidentes del periodo',
          ),
        ]) ...[
          if (section != OperatorMetric.usage) const Divider(height: 1),
          _MetricRow(
            icon: icon,
            title: title,
            detail: section != OperatorMetric.usage,
            onTap: () => showOperatorDashboardDetail(
              context,
              section: section,
              dashboard: dashboard,
              onOpenFleet: onOpenFleet,
            ),
          ),
        ],
      ],
    ),
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(width: 8),
          if (detail && MediaQuery.textScalerOf(context).scale(1) < 1.4)
            Text(
              'Ver detalle',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(AppIcons.next, size: 20),
        ],
      ),
    ),
  );
}
