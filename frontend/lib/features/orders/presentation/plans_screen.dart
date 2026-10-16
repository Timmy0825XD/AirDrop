import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tray.dart';
import 'widgets/plan_tile.dart';

/// Los planes del dueño (`GET /orders/plans`): el solicitante ve los suyos
/// y el despachador los abastecimientos que pidió su central.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<DeliveryPlan>(
      title: 'Mis planes',
      idleSubtitle: 'Entregas periódicas',
      countLabel: (n) => n == 1 ? '1 plan' : '$n planes',
      rows: ref.watch(plansProvider),
      onRefresh: () => ref.invalidate(plansProvider),
      emptyIcon: Icons.event_repeat_rounded,
      emptyText: 'Todavía no tienes planes.',
      keyOf: (plan) => plan.id,
      itemBuilder: (context, plan) => PlanTile(
        plan: plan,
        onTap: () => context.push('/orders/plans/${plan.id}'),
      ),
    );
  }
}
