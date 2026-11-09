import 'package:flutter/material.dart';

import '../../../../core/date_format.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/row_menu_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../data/geofence_models.dart';

/// Tarjeta de una geovalla: nombre, motivo y cuántos vértices tiene, con
/// "Eliminar" en el menú `⋮` (no en la fila, para no tocarlo sin querer).
/// Tocarla abre la edición.
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
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: StatusCard(
          leading: ToneTile.icon(
            icon: Icons.polyline_outlined,
            tone: Theme.of(context).colorScheme.error,
            alpha: 0.10,
          ),
          body: _GeofenceInfo(geofence: geofence),
          status: _statusOf(geofence),
          // La temporal la levantó la consola y vence sola: no se elimina.
          action: geofence.isTemporary
              ? const SizedBox.shrink()
              : RowMenuButton(
                  actions: [
                    RowMenuAction(
                      label: 'Eliminar',
                      icon: Icons.delete_outline_rounded,
                      destructive: true,
                      onSelected: onDelete,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// El nombre y el motivo.
class _GeofenceInfo extends StatelessWidget {
  const _GeofenceInfo({required this.geofence});

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
          geofence.reason,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "Temporal · vence 3:30 p. m." si es de la consola; si no, sus vértices.
StatusPill _statusOf(Geofence geofence) {
  if (geofence.expiresAt case final until?) {
    return StatusPill(
      label: 'Temporal · vence ${formatClock(until)}',
      tone: PillTone.attention,
    );
  }
  return StatusPill(
    label: '${geofence.polygon.vertices.length} vértices',
    tone: PillTone.negative,
  );
}
