import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import 'requester_next_delivery.dart';
import 'requester_plans_values.dart';

class RequesterPlansNext extends StatelessWidget {
  const RequesterPlansNext({
    super.key,
    required this.plans,
    required this.orders,
    required this.loading,
    required this.error,
    required this.onRetry,
    this.deliveryBuilder,
    this.noDeliveryMessage =
        'Revisa el calendario de tus planes o crea una nueva entrega periódica.',
  });
  final List<DeliveryPlan> plans;
  final List<Order> orders;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget Function(RequesterPlanDelivery)? deliveryBuilder;
  final String noDeliveryMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Skeleton(height: 230, radius: 20);
    if (error != null) {
      return _NextNotice(
        title: 'No pudimos consultar tu próxima entrega',
        message: error!,
        action: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      );
    }
    final next = nextRequesterPlanDelivery(plans, orders);
    if (next != null) {
      return deliveryBuilder?.call(next) ??
          RequesterNextDelivery(delivery: next);
    }
    final allPaused =
        plans.any((p) => p.status == PlanStatus.active) &&
        plans
            .where((p) => p.status == PlanStatus.active)
            .every((p) => p.paused);
    return _NextNotice(
      title: allPaused
          ? 'Tus entregas están en pausa'
          : 'Sin próximas entregas',
      message: allPaused
          ? 'Abre un plan para reanudar su calendario cuando lo necesites.'
          : noDeliveryMessage,
    );
  }
}

class _NextNotice extends StatelessWidget {
  const _NextNotice({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.plans, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 10), action!],
      ],
    ),
  );
}
