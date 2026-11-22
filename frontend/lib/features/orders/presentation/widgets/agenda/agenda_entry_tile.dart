import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../../../data/agenda_models.dart';
import '../../order_format.dart';
import '../order_status_chip.dart';
import 'agenda_entry_checks.dart';
import 'agenda_departure.dart';

/// Una entrega se revisa en el pedido; este acceso no autoriza ni carga.
class AgendaEntryTile extends StatelessWidget {
  const AgendaEntryTile({super.key, required this.entry, required this.onTap});
  final AgendaOrder entry;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EntryHeading(entry: entry),
        const SizedBox(height: 10),
        AgendaEntryChecks(entry: entry),
        const SizedBox(height: 8),
        AgendaDeparture(departBefore: entry.departBefore),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            children: [
              Expanded(child: Text('Revisar entrega')),
              Icon(AppIcons.next, size: 18),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final inline =
          box.maxWidth >= 280 &&
          MediaQuery.textScalerOf(context).scale(14) < 19;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(AppIcons.medication, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.order.medicationName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${unitsLabel(entry.order.quantity)} · ${destinationLabel(entry.order)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!inline) ...[
                  const SizedBox(height: 6),
                  OrderStatusChip(status: entry.order.status),
                ],
              ],
            ),
          ),
          if (inline) ...[
            const SizedBox(width: 10),
            OrderStatusChip(status: entry.order.status),
          ],
        ],
      );
    },
  );
}
