import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/row_menu_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../data/geofence_models.dart';
import 'geofence_tile_parts.dart';

/// Tarjeta de una geovalla del catálogo (RU-19): clase, forma y estado.
/// Con [onDelete] (operativa del operador) trae "Eliminar" en el menú `⋮`.
class GeofenceTile extends StatelessWidget {
  const GeofenceTile({
    super.key,
    required this.geofence,
    required this.onTap,
    this.onDelete,
  });

  final Geofence geofence;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final delete = onDelete;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: StatusCard(
          leading: ToneTile.icon(
            icon: geofenceIcon(geofence),
            tone: Theme.of(context).colorScheme.error,
            alpha: geofence.active ? 0.10 : 0.04,
          ),
          body: GeofenceTileInfo(geofence: geofence),
          status: geofenceStatus(geofence),
          action: delete == null
              ? const SizedBox.shrink()
              : RowMenuButton(
                  actions: [
                    RowMenuAction(
                      label: 'Eliminar',
                      icon: Icons.delete_outline_rounded,
                      destructive: true,
                      onSelected: delete,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
