import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../delivery/presentation/widgets/receive_order_button.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../order_status_chip.dart';
import '../requester_plans/requester_plans_next.dart';
import '../requester_plans/requester_plans_values.dart';

class HubPlansOverview extends StatelessWidget {
  const HubPlansOverview({
    super.key,
    required this.plans,
    required this.orders,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onCreate,
  });
  final List<DeliveryPlan> plans;
  final List<Order> orders;
  final bool loading;
  final String? error;
  final VoidCallback onRetry, onCreate;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(AppIcons.add),
        label: const Text('Nuevo abastecimiento'),
      ),
      const SizedBox(height: 28),
      Text('La próxima entrega', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      RequesterPlansNext(
        plans: plans,
        orders: orders,
        loading: loading,
        error: error,
        onRetry: onRetry,
        noDeliveryMessage:
            'Revisa el calendario o crea un nuevo abastecimiento.',
        deliveryBuilder: (delivery) => _HubNextDelivery(delivery: delivery),
      ),
      const SizedBox(height: 28),
    ],
  );
}

class _HubNextDelivery extends StatelessWidget {
  const _HubNextDelivery({required this.delivery});
  final RequesterPlanDelivery delivery;
  @override
  Widget build(BuildContext context) {
    final order = delivery.order;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatDay(
              order.scheduledFor ?? isoDate(delivery.day),
              relative: false,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            order.medicationName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(unitsLabel(order.quantity)),
          const SizedBox(height: 8),
          Text(formatSlot(order.scheduledAt, order.windowEndsAt)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OrderStatusChip(status: order.status),
          ),
          const SizedBox(height: 16),
          if (order.status == OrderStatus.awaitingDelivery)
            ReceiveOrderButton(
              orderId: order.id,
              landed: true,
              icon: AppIcons.deliveryCode,
            ),
          TextButton(
            onPressed: () => context.push('/orders/${order.id}'),
            child: const Text('Ver entrega'),
          ),
          OutlinedButton(
            onPressed: () => context.push('/orders/plans/${delivery.plan.id}'),
            child: const Text('Ver abastecimiento'),
          ),
        ],
      ),
    );
  }
}
