import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../../../core/date_format.dart';
import '../../data/fleet_models.dart';

/// Un periodo del historial de taller: el tipo, el motivo, desde cuándo,
/// la fecha estimada (solo en mantenimiento), cuántos vuelos llevaba y si
/// sigue abierto o cuándo se cerró.
class MaintenancePeriodTile extends StatelessWidget {
  const MaintenancePeriodTile({super.key, required this.period});

  final MaintenancePeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final repair = period.kind == MaintenanceKind.maintenance;
    final until = period.estimatedEndDate;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToneTile.icon(
            icon: repair ? Icons.build_outlined : Icons.block_rounded,
            tone: repair ? colors.primary : colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period.kind.label, style: theme.textTheme.titleSmall),
                if (period.reason.isNotEmpty)
                  Text(period.reason, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  [
                    'Desde ${formatDateTime(period.startedAt)}',
                    if (until != null)
                      'Estimado hasta el ${formatDay(until, relative: false)}',
                    'Llevaba ${period.flightsAtStart} vuelos',
                  ].join(' · '),
                  style: muted,
                ),
                const SizedBox(height: 6),
                period.isOpen
                    ? const StatusPill(
                        label: 'Abierto',
                        tone: PillTone.attention,
                      )
                    : Text(
                        'Cerrado el ${formatDateTime(period.closedAt)}',
                        style: muted,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
