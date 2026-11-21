import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/requester/requester_home_links.dart';
import '../../../data/order_models.dart';
import 'requester_plan_list.dart';
import 'requester_plans_empty.dart';
import 'requester_plans_next.dart';

class RequesterPlansContent extends StatelessWidget {
  const RequesterPlansContent({
    super.key,
    required this.plans,
    required this.orders,
    this.deliveriesLoading = false,
    this.deliveryError,
    required this.onRetryDeliveries,
  });
  final List<DeliveryPlan> plans;
  final List<Order> orders;
  final bool deliveriesLoading;
  final String? deliveryError;
  final VoidCallback onRetryDeliveries;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const RequesterPlansEmpty();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RequesterHomeLink(
          icon: AppIcons.createPlan,
          title: 'Crear entrega periódica',
          onTap: () => context.push('/orders/plans/new'),
        ),
        const SizedBox(height: 28),
        Text(
          'La próxima entrega',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        RequesterPlansNext(
          plans: plans,
          orders: orders,
          loading: deliveriesLoading,
          error: deliveryError,
          onRetry: onRetryDeliveries,
        ),
        const SizedBox(height: 28),
        Text('Tus planes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        RequesterPlanList(plans: plans),
      ],
    );
  }
}
