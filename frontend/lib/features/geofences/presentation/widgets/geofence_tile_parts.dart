import 'package:flutter/material.dart';

import '../../../../core/date_format.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/geofence_models.dart';
import 'geofence_facts.dart';

/// El nombre y, debajo, la clase con la forma ("Prohibida · Círculo de 100 m").
class GeofenceTileInfo extends StatelessWidget {
  const GeofenceTileInfo({super.key, required this.geofence});

  final Geofence geofence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          geofence.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${geofence.geofenceClass.label} · ${shapeLabel(geofence)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

IconData geofenceIcon(Geofence geofence) => switch (geofence.geofenceClass) {
  GeofenceClass.aerodrome => Icons.flight_takeoff_rounded,
  GeofenceClass.heliport => Icons.local_hospital_rounded,
  GeofenceClass.prohibited => Icons.shield_outlined,
  _ => Icons.polyline_rounded,
};

/// Legal: activa o desactivada. Operativa: su categoría o cuándo vence.
StatusPill geofenceStatus(Geofence geofence) {
  if (geofence.isLegal) {
    return geofence.active
        ? const StatusPill(label: 'Norma · activa', tone: PillTone.negative)
        : const StatusPill(label: 'Desactivada', tone: PillTone.neutral);
  }
  if (geofence.expiresAt case final until?) {
    return StatusPill(
      label: 'Vence ${formatClock(until)}',
      tone: PillTone.attention,
    );
  }
  return StatusPill(
    label: geofence.category?.label ?? 'Operativa',
    tone: PillTone.negative,
  );
}
