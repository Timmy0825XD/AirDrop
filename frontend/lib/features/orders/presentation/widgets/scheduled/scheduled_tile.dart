import 'package:flutter/material.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../dispatcher_order_alerts.dart';
import '../dispatcher_order_card.dart';
import '../order_fact_row.dart';

class ScheduledTile extends StatelessWidget {
  const ScheduledTile({super.key, required this.entry, required this.onTap});
  final ScheduledEntry entry;
  final VoidCallback onTap;
  static StatusPill pillOf(Order order) {
    final label = order.reassignedToHub
        ? 'Viene de otra central'
        : order.fallback?.kind == FallbackKind.retry
        ? 'Reintento automático'
        : isFutureSchedule(order.scheduledFor)
        ? 'Más adelante'
        : 'Por revisar';
    return StatusPill(
      label: label,
      wrapLabel: true,
      tone:
          isFutureSchedule(order.scheduledFor) &&
              !order.reassignedToHub &&
              order.fallback?.kind != FallbackKind.retry
          ? PillTone.neutral
          : PillTone.attention,
    );
  }

  @override
  Widget build(BuildContext context) => _ScheduledCard(tile: this);
}

class _ScheduledCard extends StatelessWidget {
  const _ScheduledCard({required this.tile});
  final ScheduledTile tile;
  @override
  Widget build(BuildContext context) {
    final order = tile.entry.order;
    final future = isFutureSchedule(order.scheduledFor);
    final enough = tile.entry.availableQuantity >= order.quantity;
    return DispatcherOrderCard(
      title: order.medicationName,
      subtitle: '${unitsLabel(order.quantity)} · ${destinationLabel(order)}',
      status: ScheduledTile.pillOf(order),
      onTap: tile.onTap,
      facts: [
        OrderFactRow(
          icon: future ? AppIcons.calendar : AppIcons.clock,
          label:
              '${future ? '${formatDay(order.scheduledFor!)} · ' : ''}${formatSlot(order.scheduledAt, order.windowEndsAt)}',
        ),
        OrderFactRow(
          icon: enough ? AppIcons.check : AppIcons.warning,
          label: enough
              ? 'Stock disponible · ${tile.entry.availableQuantity} unidades'
              : 'Stock insuficiente · ${tile.entry.availableQuantity} unidades',
          color: enough ? context.palette.success : context.palette.warning,
        ),
        if (order.requiresColdChain)
          const OrderFactRow(
            icon: AppIcons.coldChain,
            label: 'Cadena de frío · 2 a 8 °C',
          ),
        if (future)
          OrderFactRow(
            icon: AppIcons.clock,
            label: 'Aún no se puede autorizar',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        if (order.coldChainAlert || order.statusReason != null)
          DispatcherOrderAlerts(order: order),
      ],
      footer: future
          ? OrderDetailAction(onTap: tile.onTap)
          : FilledButton(
              onPressed: tile.onTap,
              child: const Text('Revisar entrega'),
            ),
    );
  }
}
