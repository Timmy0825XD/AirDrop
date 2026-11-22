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
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QueueIndicators(entry: entry),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(AppIcons.medication, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    entry.order.medicationName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${unitsLabel(entry.order.quantity)} · ${destinationLabel(entry.order)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 7),
                  QueueFacts(entry: entry),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QueueReviewButton(onTap: onTap),
      ],
    ),
  );
}

class _QueueReviewButton extends StatelessWidget {
  const _QueueReviewButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: const Row(
      children: [
        Expanded(child: Text('Revisar solicitud')),
        Icon(AppIcons.next, size: 18),
      ],
    ),
  );
}
