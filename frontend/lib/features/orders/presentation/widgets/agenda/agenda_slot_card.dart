import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/agenda_models.dart';
import '../../order_format.dart';
import 'agenda_entry_tile.dart';

/// Una tarjeta por franja; las entregas se separan con líneas, sin tarjetas anidadas.
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
  Widget build(BuildContext context) => GlassCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SlotHeader(slot: slot, drones: drones),
        for (final (index, entry) in slot.orders.indexed) ...[
          Divider(
            height: 1,
            indent: index == 0 ? 0 : 18,
            endIndent: index == 0 ? 0 : 18,
          ),
          AgendaEntryTile(entry: entry, onTap: () => onOpen(entry.order.id)),
        ],
      ],
    ),
  );
}

class _SlotHeader extends StatelessWidget {
  const _SlotHeader({required this.slot, required this.drones});
  final AgendaSlot slot;
  final int drones;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.clock,
              size: 22,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Franja de las ${formatTimeText(slot.time)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${slot.orders.length} ${slot.orders.length == 1 ? 'entrega' : 'entregas'} · '
          '$drones ${drones == 1 ? 'dron' : 'drones'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (slot.overCapacity) ...[
          const SizedBox(height: 12),
          const WarningBanner(
            message: 'Más entregas que drones en esta franja.',
            icon: AppIcons.flight,
          ),
        ],
      ],
    ),
  );
}
