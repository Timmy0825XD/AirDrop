import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/sliding_segmented.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';
import 'widgets/order_tray.dart';

/// Las entregas por confirmar arriba (RU-30), sin desordenar lo demás.
List<Order> awaitingFirst(List<Order> rows) => [
  ...rows.where((o) => o.status == OrderStatus.awaitingConfirmation),
  ...rows.where((o) => o.status != OrderStatus.awaitingConfirmation),
];

/// Lo que ya terminó para el solicitante; lo demás está "en curso". La
/// cifra del inicio y el filtro de Mis pedidos cuentan igual.
const requesterClosedStatuses = {
  OrderStatus.delivered,
  OrderStatus.returned,
  OrderStatus.rejected,
  OrderStatus.cancelled,
};

bool isRequesterOrderOpen(Order order) =>
    !requesterClosedStatuses.contains(order.status);

/// "Mis pedidos" del solicitante (`GET /orders/mine`): lo más nuevo
/// primero, con su estado, "Ver vuelo" cuando el dron va en camino y
/// "Recibir pedido" cuando ya llegó. Con [onlyOpen] (`?filtro=en-curso`,
/// desde la cifra del inicio) solo lo que sigue en curso. Se refresca cada
/// 10 s.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key, this.onlyOpen = false});

  /// La ruta filtrada, la que abre la cifra "Pedidos en curso".
  static const openPath = '/orders/mine?filtro=en-curso';

  final bool onlyOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<Order>(
      title: 'Mis pedidos',
      idleSubtitle: 'Lo que has pedido',
      countLabel: (n) => onlyOpen
          ? (n == 1 ? '1 pedido en curso' : '$n pedidos en curso')
          : (n == 1 ? '1 pedido' : '$n pedidos'),
      // Lo que espera confirmación va primero; el resto, en el orden de Nest.
      rows: ref
          .watch(mineProvider)
          .whenData(
            (rows) => awaitingFirst(
              onlyOpen ? rows.where(isRequesterOrderOpen).toList() : rows,
            ),
          ),
      onRefresh: () => ref.invalidate(mineProvider),
      emptyIcon: Icons.receipt_long_outlined,
      emptyText: onlyOpen
          ? 'No tienes pedidos en curso.'
          : 'Todavía no tienes pedidos.',
      bottom: SlidingSegmented<bool>(
        options: const [
          SegmentOption(false, 'Todos'),
          SegmentOption(true, 'En curso'),
        ],
        selected: onlyOpen,
        onChanged: (open) =>
            context.go(open ? openPath : '/orders/mine'),
      ),
      keyOf: (order) => order.id,
      itemBuilder: (context, order) => OrderTile(
        order: order,
        forRequester: true,
        canReceive: order.status == OrderStatus.awaitingDelivery,
        onTap: () => context.push('/orders/${order.id}'),
      ),
    );
  }
}
