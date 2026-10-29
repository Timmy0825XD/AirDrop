import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/agenda_models.dart';
import 'agenda_entry_tile.dart';

/// Una franja de la agenda: la hora, cuántas entregas para cuántos drones
/// (con aviso si no alcanzan) y cada entrega.
class AgendaSlotCard extends StatelessWidget {
  const AgendaSlotCard({
    super.key,
    required this.slot,
    required this.drones,
    required this.onOpen,
  });

  final AgendaSlot slot;
  final int drones;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return DetailSection(
      title: 'Franja de las ${slot.time}',
      icon: Icons.schedule_rounded,
      tone: slot.overCapacity ? palette.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${slot.deliveries} entregas · $drones drones',
                style: theme.textTheme.bodyMedium,
              ),
              if (slot.overCapacity)
                const StatusPill(
                  label: 'Más entregas que drones',
                  tone: PillTone.attention,
                ),
            ],
          ),
          for (final entry in slot.orders) ...[
            const SizedBox(height: 10),
            AgendaEntryTile(entry: entry, onTap: () => onOpen(entry.order.id)),
          ],
        ],
      ),
    );
  }
}
