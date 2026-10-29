import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../data/order_models.dart';
import 'order_row_card.dart';
import '../order_format.dart';

/// Un plan en la lista: qué, cada cuánto, la ventana de fechas y su
/// estado. Si ya se puede extender, lo dice.
class PlanTile extends StatelessWidget {
  const PlanTile({super.key, required this.plan, required this.onTap});

  final DeliveryPlan plan;
  final VoidCallback onTap;

  static Widget pillOf(DeliveryPlan plan) {
    if (plan.status == PlanStatus.active && plan.paused) {
      return const StatusPill(label: 'En pausa', tone: PillTone.attention);
    }
    return StatusPill(
      label: plan.status.label,
      tone: plan.status == PlanStatus.active
          ? PillTone.positive
          : PillTone.negative,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrderRowCard(
      icon: Icons.event_repeat_rounded,
      tone: Theme.of(context).colorScheme.primary,
      title: plan.medicationName,
      accent: '${scheduleLabel(plan)} · ${plan.quantity} und.',
      detail: plan.renewalDue && plan.canExtend
          ? 'Puedes extenderlo otras 8 semanas.'
          : '${plan.startDate} al ${plan.windowEndsOn}',
      pill: pillOf(plan),
      onTap: onTap,
    );
  }
}
