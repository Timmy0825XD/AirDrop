import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tray.dart';
import 'widgets/plan_tile.dart';

/// Los planes del dueño (`GET /orders/plans`): el solicitante ve los suyos
/// y el despachador los abastecimientos que pidió su central (por eso a él
/// la pantalla le dice "Mis abastecimientos", como el acceso de "Más").
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).value?.user?.role;
    final supply = role == UserRole.dispatcher;
    return OrderTray<DeliveryPlan>(
      title: supply ? 'Mis abastecimientos' : 'Mis planes',
      idleSubtitle: supply ? 'Lo que tu central pidió' : 'Entregas periódicas',
      countLabel: (n) => n == 1 ? '1 plan' : '$n planes',
      rows: ref.watch(plansProvider),
      onRefresh: () => ref.invalidate(plansProvider),
      emptyIcon: Icons.event_repeat_rounded,
      emptyText: supply
          ? 'Todavía no has pedido abastecimientos.'
          : 'Todavía no tienes planes.',
      keyOf: (plan) => plan.id,
      itemBuilder: (context, plan) => PlanTile(
        plan: plan,
        onTap: () => context.push('/orders/plans/${plan.id}'),
      ),
    );
  }
}
