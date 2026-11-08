import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock/sim_clock.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/order_row_card.dart';
import 'widgets/order_tray.dart';
import 'widgets/queue_wait.dart';

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
/// central y hace cuánto espera ("Espera 6 min", ámbar a los 3 y rojo a
/// los 5 o si Nest la marcó sin atender). "Viene de otra central" si otra
/// central sin dron se la pasó (CU-31).
class QueueTile extends StatelessWidget {
  const QueueTile({super.key, required this.entry, required this.onTap});

  final QueueEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final toHub = order.destinationKind == DestinationKind.hub;
    final wait = queueWaitMinutes(order.createdAt, simClock.now());
    return OrderRowCard(
      icon: toHub ? Icons.home_work_outlined : Icons.person_outline_rounded,
      tone: Theme.of(context).colorScheme.error,
      title: order.medicationName,
      accent: '${order.quantity} und. · ${destinationLabel(order)}',
      detail:
          '${entry.availableQuantity} en stock · '
          '${formatAgo(order.createdAt)}',
      pill: order.reassignedToHub
          ? const StatusPill(
              label: 'Viene de otra central',
              tone: PillTone.attention,
            )
          : StatusPill(
              label: queueWaitLabel(wait),
              tone: queueWaitTone(wait, unattended: entry.unattended),
            ),
      onTap: onTap,
    );
  }
}
