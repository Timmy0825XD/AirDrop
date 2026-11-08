import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_palette.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';
import 'dashboard_period.dart';

/// Uso de la flota en el periodo: qué parte del tiempo estuvo disponible,
/// en misión y en taller (una barra apilada), y los vuelos y km.
class FleetUsageCard extends StatelessWidget {
  const FleetUsageCard({super.key, required this.dashboard});

  final FleetDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final parts = [
      ('Disponible', dashboard.availablePercent, palette.success),
      ('En misión', dashboard.inMissionPercent, theme.colorScheme.primary),
      ('En taller', dashboard.inShopPercent, palette.warning),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('USO DE LA FLOTA', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Text(
            '${dashboard.flights} vuelos · ${decimal(dashboard.km)} km',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _StackedBar(parts: parts),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final (label, percent, color) in parts)
                Text(
                  '● $label ${percent.round()} %',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La barra partida en tramos proporcionales; vacía si todo es cero.
class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.parts});

  final List<(String, double, Color)> parts;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 12,
        color: track,
        child: Row(
          children: [
            for (final (_, percent, color) in parts)
              if (percent > 0)
                Expanded(
                  flex: (percent * 10).round().clamp(1, 1000),
                  child: Container(color: color),
                ),
          ],
        ),
      ),
    );
  }
}
