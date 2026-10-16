import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';

/// Historial del solicitante (`GET /orders/mine`).
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(mineProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: AutoRefresh(
        onTick: () => ref.invalidate(mineProvider),
        child: mine.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (rows) {
            if (rows.isEmpty) {
              return const Center(child: Text('Todavía no tienes pedidos.'));
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(mineProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => OrderTile(
                  order: rows[i],
                  onTap: () => context.go('/orders/${rows[i].id}'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
