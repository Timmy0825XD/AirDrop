import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/status_pill.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/order_row_card.dart';
import 'widgets/order_tray.dart';

/// Programados en recibido (`GET /orders/scheduled`): las entregas de los
/// planes que tu central puede soltar. Los que aún no llegan a su fecha se
/// marcan "Más adelante" (Nest no deja autorizarlos antes).
class ScheduledScreen extends ConsumerWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<ScheduledEntry>(
      title: 'Programados',
      idleSubtitle: 'Entregas de los planes',
      countLabel: (n) =>
          n == 1 ? '1 entrega programada' : '$n entregas programadas',
      rows: ref.watch(scheduledProvider),
      onRefresh: () => ref.invalidate(scheduledProvider),
      emptyIcon: Icons.event_available_rounded,
      emptyText: 'No hay entregas programadas en recibido.',
      keyOf: (entry) => entry.order.id,
      itemBuilder: (context, entry) => ScheduledTile(
        entry: entry,
        onTap: () => context.push('/orders/${entry.order.id}'),
      ),
    );
  }
}

class ScheduledTile extends StatelessWidget {
  const ScheduledTile({super.key, required this.entry, required this.onTap});

  final ScheduledEntry entry;
  final VoidCallback onTap;

  /// Lo más importante primero: viene de otra central, se reintenta solo,
  /// o si es para hoy o más adelante.
  static StatusPill pillOf(Order order) {
    if (order.reassignedToHub) {
      return const StatusPill(
        label: 'Viene de otra central',
        tone: PillTone.attention,
      );
    }
    if (order.fallback?.kind == FallbackKind.retry) {
      return const StatusPill(
        label: 'Reintento automático',
        tone: PillTone.attention,
      );
    }
    return isFutureSchedule(order.scheduledFor)
        ? const StatusPill(label: 'Más adelante', tone: PillTone.neutral)
        : const StatusPill(label: 'Hoy', tone: PillTone.attention);
  }

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    final date = order.scheduledFor;
    final slot = order.scheduledAt == null
        ? ''
        : ' · ${formatSlot(order.scheduledAt, order.windowEndsAt)}';
    return OrderRowCard(
      icon: Icons.event_outlined,
      tone: Theme.of(context).colorScheme.primary,
      title: order.medicationName,
      accent:
          '${order.quantity} und. · ${destinationLabel(order)}'
          '${date == null ? '' : ' · $date'}$slot',
      detail: 'Disponible: ${entry.availableQuantity}',
      pill: pillOf(order),
      onTap: onTap,
    );
  }
}
