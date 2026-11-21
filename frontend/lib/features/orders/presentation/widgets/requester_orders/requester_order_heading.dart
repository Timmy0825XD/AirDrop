import 'package:flutter/material.dart';

import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../order_status_chip.dart';
import 'requester_order_display.dart';

class RequesterOrderHeading extends StatelessWidget {
  const RequesterOrderHeading({
    super.key,
    required this.order,
    required this.expanded,
  });
  final Order order;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrderStatusLine(order: order),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                order.medicationName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!expanded) ...[
              const SizedBox(width: 8),
              const Icon(AppIcons.next),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${order.quantity} ${order.quantity == 1 ? 'unidad' : 'unidades'}'
          ' · ${order.patient == null ? 'Para ti' : 'Para alguien a tu cargo'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OrderStatusLine extends StatelessWidget {
  const _OrderStatusLine({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 6,
    children: [
      StatusPill(
        label: requesterOrderTitle(order.status),
        tone: order.status == OrderStatus.inFlight
            ? PillTone.neutral
            : OrderStatusChip.toneOf(order.status),
      ),
      if (order.createdAt != null)
        Text(
          formatAgo(order.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );
}
