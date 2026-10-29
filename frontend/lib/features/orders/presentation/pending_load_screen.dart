import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tray.dart';
import 'widgets/pending_load/pending_load_tile.dart';

/// Bandeja "Pendiente de carga" del despachador (`GET /orders/pending-load`).
///
/// Aquí llegan los pedidos que su central ya autorizó: el dron está
/// reservado y espera el insumo. Confirmar la carga arranca el vuelo, saca
/// el pedido de aquí y lo pasa a "Vuelos en curso".
class PendingLoadScreen extends ConsumerStatefulWidget {
  const PendingLoadScreen({super.key});

  @override
  ConsumerState<PendingLoadScreen> createState() => _PendingLoadScreenState();
}

class _PendingLoadScreenState extends ConsumerState<PendingLoadScreen> {
  /// Filas esperando la respuesta, para apagar solo su botón.
  final _confirming = <String>{};

  Future<void> _confirm(String id) async {
    setState(() => _confirming.add(id));
    try {
      await ref.read(orderDispatchProvider.notifier).confirmLoad(id);
      if (mounted) {
        showAppSnack(
          context,
          'Carga confirmada. El vuelo arranca en segundos.',
          actionLabel: 'Ver vuelo',
          onAction: () => context.push('/tracking/$id'),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _confirming.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrderTray<Order>(
      title: 'Pendiente de carga',
      idleSubtitle: 'Drones reservados esperando el insumo',
      countLabel: (n) =>
          n == 1 ? '1 dron espera la carga' : '$n drones esperan la carga',
      rows: ref.watch(pendingLoadProvider),
      onRefresh: () => ref.invalidate(pendingLoadProvider),
      emptyIcon: Icons.inventory_2_outlined,
      emptyText: 'No hay drones esperando carga.',
      keyOf: (order) => order.id,
      itemBuilder: (context, order) => PendingLoadTile(
        order: order,
        confirming: _confirming.contains(order.id),
        onConfirm: () => _confirm(order.id),
        onOpen: () => context.push('/orders/${order.id}'),
      ),
    );
  }
}
