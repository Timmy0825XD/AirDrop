import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';
import 'widgets/order_tray.dart';

/// "Mis pedidos" del solicitante (`GET /orders/mine`): lo más nuevo
/// primero, con su estado y "Ver vuelo" cuando el dron va en camino. Se
/// refresca cada 10 s.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<Order>(
      title: 'Mis pedidos',
      idleSubtitle: 'Lo que has pedido',
      countLabel: (n) => n == 1 ? '1 pedido' : '$n pedidos',
      rows: ref.watch(mineProvider),
      onRefresh: () => ref.invalidate(mineProvider),
      emptyIcon: Icons.receipt_long_outlined,
      emptyText: 'Todavía no tienes pedidos.',
      keyOf: (order) => order.id,
      itemBuilder: (context, order) => OrderTile(
        order: order,
        onTap: () => context.push('/orders/${order.id}'),
      ),
    );
  }
}
