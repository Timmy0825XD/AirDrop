import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../delivery/presentation/widgets/receive_order_button.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../order_status_chip.dart';
import '../requester_plans/requester_plans_values.dart';

class HubNextDelivery extends StatelessWidget {
  const HubNextDelivery({super.key, required this.delivery, this.originName});
  final RequesterPlanDelivery delivery;
  final String? originName;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubDeliveryHeading(delivery: delivery),
        const SizedBox(height: 16),
        _DeliveryLine(
          icon: AppIcons.hub,
          value: originName == null
              ? 'Desde la central de origen'
              : 'Desde $originName',
        ),
        const SizedBox(height: 10),
        _DeliveryLine(
          icon: AppIcons.clock,
          value: formatSlot(
            delivery.order.scheduledAt,
            delivery.order.windowEndsAt,
          ),
        ),
        const SizedBox(height: 18),
        if (delivery.order.status == OrderStatus.awaitingDelivery) ...[
          ReceiveOrderButton(
            orderId: delivery.order.id,
            landed: true,
            icon: AppIcons.deliveryCode,
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          onPressed: () => context.push('/orders/plans/${delivery.plan.id}'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Ver abastecimiento'),
        ),
        TextButton(
          onPressed: () => context.push('/orders/${delivery.order.id}'),
          child: const Text('Ver entrega'),
        ),
      ],
    ),
  );
}

class _HubDeliveryHeading extends StatelessWidget {
  const _HubDeliveryHeading({required this.delivery});
  final RequesterPlanDelivery delivery;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked =
          box.maxWidth < 240 || MediaQuery.textScalerOf(context).scale(14) > 21;
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HubDeliveryDate(day: delivery.day),
                const SizedBox(height: 12),
                _HubDeliveryDescription(delivery: delivery),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HubDeliveryDate(day: delivery.day),
                const SizedBox(width: 16),
                Expanded(child: _HubDeliveryDescription(delivery: delivery)),
              ],
            );
    },
  );
}

class _HubDeliveryDate extends StatelessWidget {
  const _HubDeliveryDate({required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context) => Semantics(
    label: formatDay(isoDate(day), relative: false),
    excludeSemantics: true,
    child: Container(
      width: MediaQuery.textScalerOf(context).scale(14) > 21 ? 96 : 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            weekdayName(day.weekday).substring(0, 3).toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            '${day.day}',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _HubDeliveryDescription extends StatelessWidget {
  const _HubDeliveryDescription({required this.delivery});
  final RequesterPlanDelivery delivery;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        delivery.order.medicationName,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 5),
      Text(
        '${unitsLabel(delivery.order.quantity)} · ${scheduleLabel(delivery.plan)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      OrderStatusChip(status: delivery.order.status),
    ],
  );
}

class _DeliveryLine extends StatelessWidget {
  const _DeliveryLine({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}
