import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/date_format.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_palette.dart';
import '../../data/geofence_models.dart';
import 'geofence_facts.dart';

class GeofenceTileInfo extends StatelessWidget {
  const GeofenceTileInfo({super.key, required this.geofence});
  final Geofence geofence;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = geofence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          g.isLegal
              ? (g.legalBasis ?? 'Restricción aeronáutica')
              : (g.reason ??
                    (geofenceIsActive(g)
                        ? 'Restricción operativa'
                        : 'Sin restricción vigente')),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${g.geofenceClass.label} · ${shapeLabel(g)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (g.expiresAt case final expiry?) ...[
          const SizedBox(height: 3),
          Text(
            '${expiry.isAfter(simClock.now()) ? 'Hasta' : 'Venció'} ${formatDateTime(expiry)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class GeofenceStatus extends StatelessWidget {
  const GeofenceStatus({super.key, required this.geofence});
  final Geofence geofence;
  @override
  Widget build(BuildContext context) {
    final active = geofenceIsActive(geofence);
    final color = !active
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : geofence.isLegal
        ? context.palette.danger
        : context.palette.warning;
    final label =
        '${geofence.isLegal ? 'Zona legal' : geofence.geofenceClass.label} · ${active ? 'Activa' : 'Inactiva'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

bool geofenceIsActive(Geofence g) =>
    g.active &&
    (g.isLegal || g.expiresAt == null || g.expiresAt!.isAfter(simClock.now()));

IconData geofenceIcon(Geofence g) =>
    g.isLegal ? AppIcons.lock : AppIcons.geofences;
