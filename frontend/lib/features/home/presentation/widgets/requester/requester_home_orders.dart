import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../orders/data/order_models.dart';
import 'requester_current_order.dart';
import 'requester_empty_card.dart';
import 'requester_home_values.dart';
import '../home_section_heading.dart';

class RequesterHomeOrders extends StatelessWidget {
  const RequesterHomeOrders({
    super.key,
    required this.orders,
    required this.onRetry,
  });
  final AsyncValue<List<Order>> orders;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeSectionHeading(
        title: 'Tus pedidos',
        onViewAll: () => context.go('/orders/mine'),
      ),
      orders.when(
        loading: () => const Skeleton(height: 150, radius: 20),
        error: (error, _) => SizedBox(
          height: 230,
          child: MessageView.error(
            message: ApiException.messageOf(error),
            action: TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
        ),
        data: (rows) => _CurrentOrders(orders: requesterCurrentOrders(rows)),
      ),
    ],
  );
}

class _CurrentOrders extends StatelessWidget {
  const _CurrentOrders({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const RequesterEmptyCard(
        icon: AppIcons.orders,
        title: 'Todo al día',
        message: 'No tienes pedidos en curso.',
        showRoute: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final order in orders.take(2))
          Padding(
            key: ValueKey(order.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: RequesterCurrentOrder(order: order),
          ),
        if (orders.length > 2)
          TextButton(
            onPressed: () => context.go('/orders/mine?filtro=en-curso'),
            child: Text('Ver los ${orders.length} pedidos en curso'),
          ),
      ],
    );
  }
}
