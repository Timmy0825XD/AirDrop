import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/order_providers.dart';
import 'requester_plans_screen.dart';
import 'widgets/hub_request/hub_plans_page.dart';

/// La lista de abastecimientos de la central; conserva las ocurrencias reales.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).value?.user?.role;
    if (role != UserRole.dispatcher) return const RequesterPlansScreen();
    final orders = ref.watch(mineProvider);
    final plans = ref.watch(plansProvider);
    final origins = ref.watch(originHubsProvider).value ?? const [];
    void refresh() {
      ref.invalidate(plansProvider);
      ref.invalidate(mineProvider);
    }

    return AutoRefresh(
      onTick: refresh,
      child: HubPlansPage(
        plans: plans.value,
        orders: orders.value ?? const [],
        loadingOrders: orders.isLoading && !orders.hasValue,
        planError: plans.hasError ? ApiException.messageOf(plans.error!) : null,
        orderError: orders.hasError
            ? ApiException.messageOf(orders.error!)
            : null,
        originNames: {for (final hub in origins) hub.id: hub.name},
        onRefresh: refresh,
        onCreate: () => context.push('/orders/hub-plans/new'),
        onRetryOrders: () => ref.invalidate(mineProvider),
      ),
    );
  }
}
