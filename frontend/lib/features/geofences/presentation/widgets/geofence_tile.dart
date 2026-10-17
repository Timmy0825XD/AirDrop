import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/row_action_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../data/geofence_models.dart';

/// Tarjeta de una geovalla: nombre, motivo y cuántos vértices tiene, con
/// "Eliminar" a la derecha. Tocarla abre la edición.
class GeofenceTile extends StatelessWidget {
  const GeofenceTile({
    super.key,
    required this.geofence,
    required this.onTap,
    required this.onDelete,
  });

  final Geofence geofence;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: StatusCard(
          leading: ToneTile.icon(
            icon: Icons.polyline_outlined,
            tone: colors.error,
            alpha: 0.10,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                geofence.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                geofence.reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          status: StatusPill(
            label: '${geofence.polygon.vertices.length} vértices',
            tone: PillTone.negative,
          ),
          action: RowActionButton(
            label: 'Eliminar',
            destructive: true,
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
