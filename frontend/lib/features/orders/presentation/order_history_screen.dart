import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';
import 'widgets/order_tray.dart';

/// Las entregas por confirmar arriba (RU-30), sin desordenar lo demás.
List<Order> awaitingFirst(List<Order> rows) => [
  ...rows.where((o) => o.status == OrderStatus.awaitingConfirmation),
  ...rows.where((o) => o.status != OrderStatus.awaitingConfirmation),
];

/// "Mis pedidos" del solicitante (`GET /orders/mine`): lo más nuevo
/// primero, con su estado, "Ver vuelo" cuando el dron va en camino y
/// "Recibir pedido" cuando ya llegó. Se refresca cada 10 s.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<Order>(
      title: 'Mis pedidos',
      idleSubtitle: 'Lo que has pedido',
      countLabel: (n) => n == 1 ? '1 pedido' : '$n pedidos',
      // Lo que espera confirmación va primero; el resto, en el orden de Nest.
      rows: ref.watch(mineProvider).whenData(awaitingFirst),
      onRefresh: () => ref.invalidate(mineProvider),
      emptyIcon: Icons.receipt_long_outlined,
      emptyText: 'Todavía no tienes pedidos.',
      keyOf: (order) => order.id,
      itemBuilder: (context, order) => OrderTile(
        order: order,
        canReceive: order.status == OrderStatus.awaitingDelivery,
        onTap: () => context.push('/orders/${order.id}'),
      ),
    );
  }
}
