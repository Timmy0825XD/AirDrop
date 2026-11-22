import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/row_menu_button.dart';
import '../../../../theme/app_icons.dart';
import '../../data/geofence_models.dart';
import 'geofence_tile_parts.dart';

/// El icono lateral, la etiqueta de estado y la acción siguen la propuesta.
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
  Widget build(BuildContext context) => ValueListenableBuilder<ClockView?>(
    valueListenable: simClock.view,
    builder: (context, _, _) => Semantics(
      button: true,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        radius: 18,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(geofenceIcon(geofence), size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GeofenceTileHeader(tile: this),
                  GeofenceTileInfo(geofence: geofence),
                  const SizedBox(height: 12),
                  _GeofenceTileAction(manages: onDelete != null),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GeofenceTileHeader extends StatelessWidget {
  const _GeofenceTileHeader({required this.tile});
  final GeofenceTile tile;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tile.geofence.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            GeofenceStatus(geofence: tile.geofence),
          ],
        ),
      ),
      if (tile.onDelete case final delete?)
        RowMenuButton(
          icon: AppIcons.more,
          actions: [
            RowMenuAction(
              label: 'Eliminar',
              icon: AppIcons.trash,
              destructive: true,
              onSelected: delete,
            ),
          ],
        ),
    ],
  );
}

class _GeofenceTileAction extends StatelessWidget {
  const _GeofenceTileAction({required this.manages});
  final bool manages;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          manages ? 'Ver y editar' : 'Consultar',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Icon(
        AppIcons.forward,
        size: 19,
        color: Theme.of(context).colorScheme.primary,
      ),
    ],
  );
}
