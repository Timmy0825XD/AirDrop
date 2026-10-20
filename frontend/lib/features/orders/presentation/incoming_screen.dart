import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';
import 'widgets/order_tray.dart';

/// "Traslados entrantes" del despachador (`GET /orders/incoming`): lo que
/// otras centrales despachan hacia la suya, lo más nuevo primero. Cuando el
/// dron aterriza en su central aparece "Recibir pedido". No hay "Ver vuelo":
/// el mapa es de la central de origen. Se refresca cada 10 s.
class IncomingScreen extends ConsumerWidget {
  const IncomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<Order>(
      title: 'Traslados entrantes',
      idleSubtitle: 'Lo que otras centrales te envían',
      countLabel: (n) => n == 1 ? '1 traslado' : '$n traslados',
      rows: ref.watch(incomingProvider),
      onRefresh: () => ref.invalidate(incomingProvider),
      emptyIcon: Icons.move_to_inbox_outlined,
      emptyText: 'Ninguna central le ha enviado nada a la tuya.',
      keyOf: (order) => order.id,
      itemBuilder: (context, order) => OrderTile(
        order: order,
        canWatch: false,
        canReceive: order.status == OrderStatus.awaitingDelivery,
        onTap: () => context.push('/orders/${order.id}'),
      ),
    );
  }
}
