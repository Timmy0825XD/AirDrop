import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import 'queue_facts.dart';
import 'queue_indicators.dart';

/// Abre la revisión existente; ningún botón de la cola autoriza ni despega.
class QueueTile extends StatelessWidget {
  const QueueTile({super.key, required this.entry, required this.onTap});
  final QueueEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QueueIndicators(entry: entry),
        const SizedBox(height: 12),
        Text(
          entry.order.medicationName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${unitsLabel(entry.order.quantity)} · ${destinationLabel(entry.order)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        QueueFacts(entry: entry),
        const SizedBox(height: 14),
        const Divider(height: 1),
        TextButton(
          onPressed: onTap,
          child: const Row(
            children: [
              Icon(AppIcons.document, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Revisar solicitud')),
              Icon(AppIcons.next, size: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
