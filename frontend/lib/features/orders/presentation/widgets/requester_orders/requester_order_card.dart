import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../../../tracking/data/telemetry_models.dart';
import '../../../../tracking/data/tracking_providers.dart';
import 'requester_delivery_steps.dart';
import 'requester_order_actions.dart';
import 'requester_order_display.dart';
import 'requester_order_heading.dart';

class RequesterOrderCard extends ConsumerWidget {
  const RequesterOrderCard({
    super.key,
    required this.order,
    required this.active,
  });
  final Order order;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flight =
        active && order.hasFlight && order.status != OrderStatus.returning
        ? ref.watch(trackingProvider(order.id))
        : null;
    final current = order.copyWith(status: flight?.status ?? order.status);
    return _OrderCardBody(
      order: current,
      telemetry: flight?.telemetry,
      expanded:
          active &&
          current.hasFlight &&
          current.status != OrderStatus.returning,
    );
  }
}

class _OrderCardBody extends StatelessWidget {
  const _OrderCardBody({
    required this.order,
    required this.telemetry,
    required this.expanded,
  });
  final Order order;
  final Telemetry? telemetry;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    void details() => context.push('/orders/${order.id}');
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      onTap: expanded ? null : details,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: expanded ? details : null,
            child: RequesterOrderHeading(order: order, expanded: expanded),
          ),
          if (expanded) ...[
            const SizedBox(height: 22),
            RequesterDeliverySteps(stage: requesterDeliveryStage(order)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1),
            ),
            RequesterOrderActions(order: order, telemetry: telemetry),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              requesterOrderDetail(order.status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (order.status == OrderStatus.awaitingConfirmation)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: details,
                  icon: const Icon(AppIcons.check),
                  label: const Text('Confirmar disponibilidad'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
