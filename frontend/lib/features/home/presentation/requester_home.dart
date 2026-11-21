import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../../auth/data/auth_models.dart';
import '../../notifications/data/notice_providers.dart';
import '../../orders/data/order_providers.dart';
import 'widgets/home_page.dart';
import 'widgets/requester/requester_home_header.dart';
import 'widgets/requester/requester_home_links.dart';
import 'widgets/requester/requester_home_orders.dart';
import 'widgets/requester/requester_home_plans.dart';
import 'widgets/requester/requester_urgent_action.dart';

/// Inicio centrado en pedir y recibir, con los mismos datos y socket del pedido.
class RequesterHome extends ConsumerWidget {
  const RequesterHome({super.key, required this.user});
  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(mineProvider);
    return AutoRefresh(
      onTick: () => ref
        ..invalidate(mineProvider)
        ..invalidate(plansProvider)
        ..invalidate(unreadCountProvider),
      child: HomePage(
        children: [
          RequesterHomeHeader(
            fullName: user.fullName,
            onNotices: () => context.push('/notifications'),
            unread: ref.watch(unreadCountProvider).value,
          ),
          const SizedBox(height: 24),
          RequesterUrgentAction(onTap: () => context.push('/orders/emergency')),
          const SizedBox(height: 28),
          RequesterHomeOrders(
            orders: orders,
            onRetry: () => ref.invalidate(mineProvider),
          ),
          const SizedBox(height: 18),
          RequesterHomePlans(orders: orders.value ?? const []),
          const SizedBox(height: 24),
          const RequesterHomeLinks(),
        ],
      ),
    );
  }
}
