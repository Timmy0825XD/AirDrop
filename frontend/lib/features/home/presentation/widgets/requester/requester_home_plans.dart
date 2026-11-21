import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../orders/data/order_models.dart';
import '../../../../orders/data/order_providers.dart';
import '../../../../orders/presentation/order_format.dart';
import 'requester_empty_card.dart';
import 'requester_home_links.dart';
import 'requester_home_values.dart';
import 'requester_section_heading.dart';

class RequesterHomePlans extends ConsumerWidget {
  const RequesterHomePlans({super.key, required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RequesterSectionHeading(
        title: 'Mis entregas periódicas',
        onViewAll: () => context.push('/orders/plans'),
      ),
      ref
          .watch(plansProvider)
          .when(
            loading: () => const Skeleton(height: 120, radius: 20),
            error: (error, _) => SizedBox(
              height: 230,
              child: MessageView.error(
                message: ApiException.messageOf(error),
                action: TextButton(
                  onPressed: () => ref.invalidate(plansProvider),
                  child: const Text('Reintentar'),
                ),
              ),
            ),
            data: (rows) => RequesterPlansSummary(
              plans: rows.where((p) => p.status == PlanStatus.active).toList(),
              orders: orders,
            ),
          ),
    ],
  );
}

class RequesterPlansSummary extends StatelessWidget {
  const RequesterPlansSummary({
    super.key,
    required this.plans,
    required this.orders,
  });
  final List<DeliveryPlan> plans;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return RequesterEmptyCard(
        icon: AppIcons.plans,
        title: 'Sin entregas periódicas activas',
        message: 'Organiza tus entregas periódicas.',
        action: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/orders/plans/new'),
            child: const Text('Crear entrega periódica'),
          ),
        ),
      );
    }
    final next = requesterNextDelivery(orders);
    final sorted = [...plans]
      ..sort(
        (a, b) => (a.id == next?.planId ? 0 : 1).compareTo(
          b.id == next?.planId ? 0 : 1,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final plan in sorted.take(2))
          Padding(
            key: ValueKey(plan.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlanLink(
              plan: plan,
              next: requesterNextDelivery(
                orders.where((o) => o.planId == plan.id).toList(),
              ),
            ),
          ),
        if (plans.length > 2)
          TextButton(
            onPressed: () => context.push('/orders/plans'),
            child: Text('Ver las ${plans.length} entregas periódicas'),
          ),
      ],
    );
  }
}

class _PlanLink extends StatelessWidget {
  const _PlanLink({required this.plan, required this.next});
  final DeliveryPlan plan;
  final Order? next;

  @override
  Widget build(BuildContext context) {
    final delivery = next;
    final detail = plan.paused
        ? 'Entregas en pausa'
        : delivery?.scheduledAt == null
        ? scheduleLabel(plan)
        : '${delivery!.status == OrderStatus.awaitingConfirmation ? 'Por confirmar' : 'Próxima entrega'}'
              ' · ${capitalized(formatDateTime(delivery.scheduledAt!))}';
    return RequesterHomeLink(
      icon: AppIcons.plans,
      title: plan.medicationName,
      subtitle: detail,
      onTap: () => context.push('/orders/plans/${plan.id}'),
    );
  }
}
