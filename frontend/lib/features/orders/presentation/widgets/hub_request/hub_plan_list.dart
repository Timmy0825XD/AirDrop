import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../theme/app_icons.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../plan_tile.dart';

/// Filas de una sola lista con separadores, dibujadas de forma perezosa.
class HubPlanList extends StatelessWidget {
  const HubPlanList({super.key, required this.plans});
  final List<DeliveryPlan> plans;
  @override
  Widget build(BuildContext context) => DecoratedSliver(
    decoration: BoxDecoration(
      color: context.palette.glass,
      border: Border.all(color: context.palette.glassBorder),
      borderRadius: BorderRadius.circular(20),
    ),
    sliver: SliverList.separated(
      itemCount: plans.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, index) => _HubPlanRow(plan: plans[index]),
    ),
  );
}

class _HubPlanRow extends StatelessWidget {
  const _HubPlanRow({required this.plan});
  final DeliveryPlan plan;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/orders/plans/${plan.id}'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, box) {
          final inline =
              box.maxWidth >= 280 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18;
          return Row(
            children: [
              Icon(
                plan.status == PlanStatus.active
                    ? AppIcons.plans
                    : AppIcons.calendar,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HubPlanDescription(plan: plan, showState: !inline),
              ),
              if (inline) ...[const SizedBox(width: 10), PlanTile.pillOf(plan)],
              const SizedBox(width: 8),
              const Icon(AppIcons.next, size: 21),
            ],
          );
        },
      ),
    ),
  );
}

class _HubPlanDescription extends StatelessWidget {
  const _HubPlanDescription({required this.plan, required this.showState});
  final DeliveryPlan plan;
  final bool showState;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        plan.medicationName,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        '${scheduleLabel(plan)} · ${unitsLabel(plan.quantity)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      if (showState) ...[const SizedBox(height: 8), PlanTile.pillOf(plan)],
      if (plan.renewalDue && plan.canExtend) ...[
        const SizedBox(height: 5),
        const Text('Puedes extenderlo otras 8 semanas.'),
      ],
    ],
  );
}
