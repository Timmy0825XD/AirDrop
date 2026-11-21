import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';
import '../requester_orders/requester_order_display.dart';

class RequesterDeliveryActions extends StatelessWidget {
  const RequesterDeliveryActions({
    super.key,
    required this.order,
    required this.onOpen,
  });
  final Order order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final confirm = order.status == OrderStatus.awaitingConfirmation;
    final scheduled = order.status == OrderStatus.scheduled;
    final color = confirm
        ? context.palette.warning
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              confirm ? AppIcons.notifications : AppIcons.plans,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                confirm
                    ? 'Confirma que podrás recibirla.'
                    : scheduled
                    ? 'Te avisaremos cuando sea hora de confirmar.'
                    : requesterOrderTitle(order.status),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onOpen,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(confirm ? 'Ver y confirmar' : 'Ver entrega'),
              const Icon(AppIcons.forward, size: 22),
            ],
          ),
        ),
      ],
    );
  }
}
