import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';

class QueueFacts extends StatelessWidget {
  const QueueFacts({super.key, required this.entry});
  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final enough = entry.availableQuantity >= entry.order.quantity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QueueFact(
          icon: enough ? AppIcons.check : AppIcons.warning,
          label: enough
              ? '${entry.availableQuantity} en stock'
              : 'Stock insuficiente: ${entry.availableQuantity} de ${entry.order.quantity}',
          color: enough ? context.palette.success : context.palette.danger,
        ),
        if (entry.order.reassignedToHub) ...[
          const SizedBox(height: 8),
          const QueueFact(
            label: 'Viene de otra central',
            icon: AppIcons.transfer,
          ),
        ],
        if (entry.order.requiresColdChain) ...[
          const SizedBox(height: 8),
          const QueueFact(
            label: 'Requiere cadena de frío',
            icon: AppIcons.coldChain,
          ),
        ],
        if (entry.order.hasPrescription) ...[
          const SizedBox(height: 8),
          const QueueFact(label: 'Fórmula adjunta', icon: AppIcons.document),
        ],
      ],
    );
  }
}

class QueueFact extends StatelessWidget {
  const QueueFact({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    this.strong = false,
  });
  final String label;
  final IconData icon;
  final Color? color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tone),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tone,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
