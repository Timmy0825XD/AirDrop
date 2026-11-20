import 'package:flutter/material.dart';

import '../../../../core/widgets/app_sheet.dart';
import '../../data/geofence_models.dart';
import 'geofence_facts.dart';
import 'geofence_history.dart';
import 'legal_zone_actions.dart';

/// La ficha de una geovalla (RU-19). Una zona legal trae su historial y,
/// para el admin, sus acciones (RU-36).
Future<void> showGeofenceDetailSheet(
  BuildContext context,
  Geofence geofence, {
  required bool isAdmin,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(geofence.name, style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 12),
            GeofenceFacts(geofence: geofence),
            if (geofence.isLegal) ...[
              const SizedBox(height: 8),
              GeofenceHistory(geofenceId: geofence.id),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                LegalZoneActions(zone: geofence),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}
