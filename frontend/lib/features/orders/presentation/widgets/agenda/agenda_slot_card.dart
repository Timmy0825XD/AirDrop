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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .04),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SlotTime(time: slot.time),
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

class _SlotTime extends StatelessWidget {
  const _SlotTime({required this.time});
  final String time;
  @override
  Widget build(BuildContext context) => Row(
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
          agendaSlotLabel(time),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

String agendaSlotLabel(String time) {
  final hour = int.tryParse(time.split(':').first);
  if (hour == null) return 'Franja de las ${formatTimeText(time)}';
  final period = hour < 12
      ? 'Mañana'
      : hour < 18
      ? 'Tarde'
      : 'Noche';
  return '$period · ${formatTimeText(time)} – ${formatTimeText('${hour + 1}:00')}';
}
