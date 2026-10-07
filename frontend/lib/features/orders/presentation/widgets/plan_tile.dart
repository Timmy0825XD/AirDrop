import 'package:flutter/material.dart';

import '../../data/order_models.dart';

class PlanTile extends StatelessWidget {
  const PlanTile({super.key, required this.plan, required this.onTap});

  final DeliveryPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.medicationName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${plan.frequency.label} · ${plan.startDate} - ${plan.windowEndsOn}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Chip(label: Text(plan.status.label)),
            ],
          ),
        ),
      ),
    );
  }
}
