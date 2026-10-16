import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../data/order_providers.dart';
import 'widgets/pending_load/pending_load_tile.dart';

/// Bandeja "Pendiente de carga" del despachador (`GET /orders/pending-load`).
///
/// Aquí llegan los pedidos que su central ya autorizó: el dron está
/// reservado y espera el insumo. Confirmar la carga arranca el vuelo y saca
/// el pedido de la bandeja. No se alimenta de la cola: autorizar mueve el
/// pedido de la cola a esta lista.
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
      // Apenas despega, el pedido sale de esta bandeja y no hay otra lista
      // de vuelos del despachador: el aviso lleva directo al mapa.
      if (mounted) {
        showAppSnack(
          context,
          'Carga confirmada. El vuelo arranca en segundos.',
          actionLabel: 'Ver vuelo',
          onAction: () => context.go('/tracking/$id'),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _confirming.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(pendingLoadProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pendiente de carga')),
      body: AutoRefresh(
        onTick: () => ref.invalidate(pendingLoadProvider),
        child: rows.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (orders) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingLoadProvider),
            child: orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No hay drones esperando carga.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => PendingLoadTile(
                      order: orders[i],
                      confirming: _confirming.contains(orders[i].id),
                      onConfirm: () => _confirm(orders[i].id),
                      onOpen: () => context.go('/orders/${orders[i].id}'),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
