import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import 'requester_plans_values.dart';

class RequesterPlanList extends StatelessWidget {
  const RequesterPlanList({super.key, required this.plans});
  final List<DeliveryPlan> plans;

  @override
  Widget build(BuildContext context) {
    final sorted = [...plans]
      ..sort(
        (a, b) => (a.status == PlanStatus.active ? 0 : 1).compareTo(
          b.status == PlanStatus.active ? 0 : 1,
        ),
      );
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, plan) in sorted.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
            _PlanRow(key: ValueKey(plan.id), plan: plan),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({super.key, required this.plan});
  final DeliveryPlan plan;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/orders/plans/${plan.id}'),
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(AppIcons.plans, size: 25),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Theme.of(context).colorScheme.outline,
          ),
          Expanded(child: _PlanDescription(plan: plan)),
          const SizedBox(width: 8),
          const Icon(AppIcons.next, size: 22),
        ],
      ),
    ),
  );
}

class _PlanDescription extends StatelessWidget {
  const _PlanDescription({required this.plan});
  final DeliveryPlan plan;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(plan.medicationName, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        '${scheduleLabel(plan)} · ${unitsLabel(plan.quantity)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      StatusPill(
        label: requesterPlanState(plan),
        tone: plan.status != PlanStatus.active
            ? PillTone.neutral
            : plan.paused
            ? PillTone.attention
            : PillTone.positive,
      ),
    ],
  );
}
