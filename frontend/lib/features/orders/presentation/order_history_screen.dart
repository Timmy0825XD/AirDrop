import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/requester_orders/requester_orders_page.dart';

/// Las ocurrencias pendientes de confirmación conservan su prioridad visual.
List<Order> awaitingFirst(List<Order> rows) => [
  ...rows.where((o) => o.status == OrderStatus.awaitingConfirmation),
  ...rows.where((o) => o.status != OrderStatus.awaitingConfirmation),
];

const requesterClosedStatuses = {
  OrderStatus.delivered,
  OrderStatus.returned,
  OrderStatus.rejected,
  OrderStatus.cancelled,
  OrderStatus.skipped,
  OrderStatus.expired,
};

bool isRequesterOrderOpen(Order order) =>
    !requesterClosedStatuses.contains(order.status);

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key, this.onlyOpen = true});
  static const openPath = '/orders/mine?filtro=en-curso';
  static const historyPath = '/orders/mine?filtro=historial';
  final bool onlyOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AutoRefresh(
    onTick: () => ref.invalidate(mineProvider),
    child: RequesterOrdersPage(
      onlyOpen: onlyOpen,
      rows: ref
          .watch(mineProvider)
          .whenData(
            (rows) => awaitingFirst(
              rows.where((o) => isRequesterOrderOpen(o) == onlyOpen).toList(),
            ),
          ),
      onRefresh: () => ref.invalidate(mineProvider),
      onFilter: (open) => context.go(open ? openPath : historyPath),
    ),
  );
}
