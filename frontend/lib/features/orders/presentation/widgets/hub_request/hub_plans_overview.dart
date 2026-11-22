import 'package:flutter/material.dart';

import '../../../data/order_models.dart';
import '../requester_plans/requester_plans_next.dart';
import 'hub_next_delivery.dart';

class HubPlansOverview extends StatelessWidget {
  const HubPlansOverview({
    super.key,
    required this.plans,
    required this.orders,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onCreate,
    this.originNames = const {},
  });
  final List<DeliveryPlan> plans;
  final List<Order> orders;
  final bool loading;
  final String? error;
  final VoidCallback onRetry, onCreate;
  final Map<String, String> originNames;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'La próxima entrega',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      RequesterPlansNext(
        plans: plans,
        orders: orders,
        loading: loading,
        error: error,
        onRetry: onRetry,
        noDeliveryMessage:
            'Revisa el calendario o crea un nuevo abastecimiento.',
        deliveryBuilder: (delivery) => HubNextDelivery(
          delivery: delivery,
          originName:
              originNames[delivery.order.originHubId ??
                  delivery.plan.originHubId],
        ),
      ),
      const SizedBox(height: 28),
    ],
  );
}
