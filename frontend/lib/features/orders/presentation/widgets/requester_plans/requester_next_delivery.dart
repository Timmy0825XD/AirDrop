import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import 'requester_delivery_actions.dart';
import 'requester_delivery_summary.dart';
import 'requester_plans_values.dart';

class RequesterNextDelivery extends StatelessWidget {
  const RequesterNextDelivery({super.key, required this.delivery});
  final RequesterPlanDelivery delivery;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RequesterDeliverySummary(delivery: delivery),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1),
        ),
        RequesterDeliveryActions(
          order: delivery.order,
          onOpen: () => context.push('/orders/${delivery.order.id}'),
        ),
        TextButton(
          onPressed: () => context.push('/orders/plans/${delivery.plan.id}'),
          child: const Text('Ver plan'),
        ),
      ],
    ),
  );
}
