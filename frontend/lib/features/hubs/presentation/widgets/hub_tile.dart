import 'package:flutter/material.dart';

import '../../../../core/colombian_phone.dart';
import '../../../../core/widgets/row_menu_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../data/hub_models.dart';
import 'hub_labels.dart';

/// Tarjeta del listado de centrales: ícono del tipo, nombre, tipo,
/// dirección y teléfono, el estado y, en el menú `⋮`, suspender o
/// reactivar (fuera de la fila, para no tocarlo sin querer).
///
/// El botón nunca ofrece la acción que ya está aplicada: Nest responde 409
/// si se repite (`Esta central ya está suspendida.`). Suspendida, la
/// tarjeta se apaga a gris.
class HubTile extends StatelessWidget {
  const HubTile({super.key, required this.hub, required this.onToggle});

  final Hub hub;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: hub.isActive ? 1 : 0.72,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      child: StatusCard(
        leading: HubTypeTile(hub: hub),
        body: _HubInfo(hub: hub),
        status: StatusPill(
          label: HubLabels.status(hub.status),
          tone: HubLabels.tone(hub.status),
        ),
        action: RowMenuButton(
          actions: [
            RowMenuAction(
              label: hub.isActive ? 'Suspender' : 'Reactivar',
              icon: hub.isActive
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              destructive: hub.isActive,
              onSelected: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

/// El cuadro con el ícono del tipo. El banco de sangre va en rojo y una
/// central suspendida, en gris. Lo reusa la hoja de confirmación.
class HubTypeTile extends StatelessWidget {
  const HubTypeTile({super.key, required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = !hub.isActive
        ? colors.onSurfaceVariant
        : hub.type == HubType.bloodBank
        ? colors.error
        : colors.primary;
    return ToneTile.icon(
      icon: HubLabels.icon(hub.type),
      tone: tone,
      alpha: hub.isActive ? 0.10 : 0.14,
    );
  }
}

class _HubInfo extends StatelessWidget {
  const _HubInfo({required this.hub});

  final Hub hub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hub.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          HubLabels.type(hub.type),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${hub.address} · ${formatColombianPhone(hub.contactPhone)}',
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
