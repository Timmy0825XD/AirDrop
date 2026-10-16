import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/status_pill.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/order_row_card.dart';
import 'widgets/order_tray.dart';

/// Cola de urgencias (`GET /orders/queue`). Va en el orden de Nest, sin
/// reordenar: la prioridad la decide el backend.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<QueueEntry>(
      title: 'Cola de urgencias',
      idleSubtitle: 'Urgencias en recibido',
      countLabel: (n) =>
          n == 1 ? '1 urgencia por atender' : '$n urgencias por atender',
      rows: ref.watch(queueProvider),
      onRefresh: () => ref.invalidate(queueProvider),
      emptyIcon: Icons.task_alt_rounded,
      emptyText: 'No hay urgencias esperando. Todo al día.',
      keyOf: (entry) => entry.order.id,
      itemBuilder: (context, entry) => QueueTile(
        entry: entry,
        onTap: () => context.push('/orders/${entry.order.id}'),
      ),
    );
  }
}

/// Una urgencia de la cola: qué y cuánto, a quién va, el stock de la
/// central y cuándo llegó. "Sin atender" si lleva rato esperando.
class QueueTile extends StatelessWidget {
  const QueueTile({super.key, required this.entry, required this.onTap});

  final QueueEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final toHub = order.destinationKind == DestinationKind.hub;
    return OrderRowCard(
      icon: toHub ? Icons.home_work_outlined : Icons.person_outline_rounded,
      tone: Theme.of(context).colorScheme.error,
      title: order.medicationName,
      accent: '${order.quantity} und. · ${destinationLabel(order)}',
      detail:
          'Disponible: ${entry.availableQuantity} · '
          '${formatBogota(order.createdAt)}',
      pill: entry.unattended
          ? const StatusPill(label: 'Sin atender', tone: PillTone.negative)
          : null,
      onTap: onTap,
    );
  }
}
