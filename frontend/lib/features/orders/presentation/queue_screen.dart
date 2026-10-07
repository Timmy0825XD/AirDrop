import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_providers.dart';
import 'order_format.dart';

/// Cola de urgencias (`GET /orders/queue`). Orden del API, sin reordenar.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cola de urgencias')),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Sin urgencias en recibido.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(queueProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final entry = rows[i];
                final order = entry.order;
                final theme = Theme.of(context);
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go('/orders/${order.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.medicationName,
                              style: theme.textTheme.titleMedium),
                          Text(
                            '${order.quantity} und. · Disponible: ${entry.availableQuantity} · ${destinationLabel(order)} · ${formatBogota(order.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (entry.unattended)
                            Chip(
                              label: const Text('Sin atender'),
                              backgroundColor: theme.colorScheme.error
                                  .withValues(alpha: 0.12),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
