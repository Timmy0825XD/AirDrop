import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/list_padding.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import 'requester_order_card.dart';

class RequesterOrdersResults extends StatelessWidget {
  const RequesterOrdersResults({
    super.key,
    required this.rows,
    required this.onlyOpen,
    required this.query,
    required this.onRefresh,
    required this.onClear,
  });
  final AsyncValue<List<Order>> rows;
  final bool onlyOpen;
  final String query;
  final VoidCallback onRefresh;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => rows.when(
    loading: () => const SkeletonList(rows: 3),
    error: (error, _) => MessageView.error(
      message: ApiException.messageOf(error),
      action: TextButton(onPressed: onRefresh, child: const Text('Reintentar')),
    ),
    data: (orders) {
      final needle = query.trim().toLowerCase();
      final shown = orders
          .where((o) => o.medicationName.toLowerCase().contains(needle))
          .toList();
      if (shown.isEmpty) {
        return MessageView(
          icon: AppIcons.orders,
          message: needle.isNotEmpty
              ? 'No encontramos pedidos con ese medicamento.'
              : onlyOpen
              ? 'No tienes pedidos en curso.'
              : 'Aún no tienes pedidos finalizados.',
          action: TextButton(
            onPressed: needle.isNotEmpty
                ? onClear
                : () => context.push('/orders/emergency'),
            child: Text(
              needle.isNotEmpty ? 'Limpiar búsqueda' : 'Pedir urgencia',
            ),
          ),
        );
      }
      return _OrderList(
        orders: shown,
        onlyOpen: onlyOpen,
        onRefresh: onRefresh,
      );
    },
  );
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.onlyOpen,
    required this.onRefresh,
  });
  final List<Order> orders;
  final bool onlyOpen;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => onRefresh(),
    child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: listPadding(context),
      itemCount: orders.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) => i == orders.length
          ? TextButton.icon(
              onPressed: () => context.push('/orders/emergency'),
              icon: const Icon(AppIcons.add),
              label: const Text('Pedir otra urgencia'),
            )
          : RequesterOrderCard(
              key: ValueKey(orders[i].id),
              order: orders[i],
              active: onlyOpen,
            ),
    ),
  );
}
