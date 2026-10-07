import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_providers.dart';

/// Programados en recibido (`GET /orders/scheduled`). Sin `Sin atender`.
class ScheduledScreen extends ConsumerWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(scheduledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Programados')),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Sin programados en recibido.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(scheduledProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final order = entries[i].order;
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
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          Text(
                            '${order.quantity} und. · Disponible: ${entries[i].availableQuantity} · ${order.scheduledFor ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall,
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
