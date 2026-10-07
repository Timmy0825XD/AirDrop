import 'package:flutter/material.dart';

import '../../data/order_models.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(status.label),
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
    );
  }
}
