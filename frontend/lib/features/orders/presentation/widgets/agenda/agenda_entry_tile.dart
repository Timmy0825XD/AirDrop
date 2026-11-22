import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../../../data/agenda_models.dart';
import '../../order_format.dart';
import '../order_status_chip.dart';
import 'agenda_entry_checks.dart';
import 'agenda_departure.dart';

/// Revisa la entrega desde su pedido; esta ficha no autoriza ni confirma cargas.
class AgendaEntryTile extends StatelessWidget {
  const AgendaEntryTile({super.key, required this.entry, required this.onTap});
  final AgendaOrder entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EntryHeading(entry: entry),
        const SizedBox(height: 14),
        AgendaEntryChecks(entry: entry),
        const SizedBox(height: 12),
        AgendaDeparture(departBefore: entry.departBefore),
        const SizedBox(height: 6),
        TextButton(
          onPressed: onTap,
          child: const Row(
            children: [
              Expanded(child: Text('Revisar entrega')),
              Icon(AppIcons.next, size: 20),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EntryHeading extends StatelessWidget {
  const _EntryHeading({required this.entry});
  final AgendaOrder entry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OrderStatusChip(status: entry.order.status),
      const SizedBox(height: 10),
      Text(
        entry.order.medicationName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        '${unitsLabel(entry.order.quantity)} · ${destinationLabel(entry.order)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
