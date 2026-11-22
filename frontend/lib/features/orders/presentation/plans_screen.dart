import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_exception.dart';
import '../../../theme/app_icons.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'requester_plans_screen.dart';
import 'widgets/order_tray.dart';
import 'widgets/plan_tile.dart';
import 'widgets/hub_request/hub_plans_overview.dart';

/// Los planes del dueño (`GET /orders/plans`): el solicitante ve los suyos
/// y el despachador los abastecimientos que pidió su central (por eso a él
/// la pantalla le dice "Mis abastecimientos", como el acceso de "Más").
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).value?.user?.role;
    if (role != UserRole.dispatcher) return const RequesterPlansScreen();
    final orders = ref.watch(mineProvider);
    final plans = ref.watch(plansProvider);
    void create() => context.push('/orders/hub-plans/new');
    return OrderTray<DeliveryPlan>(
      title: 'Mis abastecimientos',
      idleSubtitle: 'Tus entregas entre centrales.',
      countLabel: (n) => n == 1 ? '1 plan' : '$n planes',
      rows: plans,
      onRefresh: () {
        ref.invalidate(plansProvider);
        ref.invalidate(mineProvider);
      },
      emptyIcon: AppIcons.plans,
      emptyTitle: 'Tu próximo abastecimiento empieza aquí',
      emptyText:
          'Elige la central, el insumo y los días para organizar tus entregas.',
      emptyAction: FilledButton(
        onPressed: create,
        child: const Text('Crear abastecimiento'),
      ),
      beforeList: plans.value?.isNotEmpty == true
          ? HubPlansOverview(
              plans: plans.value!,
              orders: orders.value ?? const [],
              loading: orders.isLoading && !orders.hasValue,
              error: orders.hasError
                  ? ApiException.messageOf(orders.error!)
                  : null,
              onRetry: () => ref.invalidate(mineProvider),
              onCreate: create,
            )
          : null,
      keyOf: (plan) => plan.id,
      itemBuilder: (context, plan) => PlanTile(
        plan: plan,
        onTap: () => context.push('/orders/plans/${plan.id}'),
      ),
    );
  }
}
