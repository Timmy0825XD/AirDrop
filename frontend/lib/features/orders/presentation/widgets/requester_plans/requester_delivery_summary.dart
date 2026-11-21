import 'package:flutter/material.dart';

import '../../order_format.dart';
import 'requester_plans_values.dart';

class RequesterDeliverySummary extends StatelessWidget {
  const RequesterDeliverySummary({super.key, required this.delivery});
  final RequesterPlanDelivery delivery;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked =
          box.maxWidth < 290 || MediaQuery.textScalerOf(context).scale(16) > 22;
      final date = _DeliveryDate(day: delivery.day);
      final detail = _DeliveryDescription(delivery: delivery);
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [date, const SizedBox(height: 16), detail],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                date,
                const SizedBox(width: 18),
                Expanded(child: detail),
              ],
            );
    },
  );
}

class _DeliveryDate extends StatelessWidget {
  const _DeliveryDate({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: formatCalendarDay(day, relative: false),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                weekdayName(day.weekday).substring(0, 3).toUpperCase(),
                style: theme.textTheme.labelLarge,
              ),
              Text(
                '${day.day}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatCalendarDay(
                  day,
                  relative: false,
                ).split(' ').skip(2).join(' '),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryDescription extends StatelessWidget {
  const _DeliveryDescription({required this.delivery});
  final RequesterPlanDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(delivery.plan.medicationName, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          formatSlot(delivery.order.scheduledAt, delivery.order.windowEndsAt),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${unitsLabel(delivery.order.quantity)} · ${scheduleLabel(delivery.plan)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
