import 'package:flutter/material.dart';
import '../../../../core/widgets/drone_glyph.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_icons.dart';
import '../../../delivery/presentation/widgets/receive_order_button.dart';
import '../../data/order_models.dart';
import '../order_format.dart';
import 'dispatcher_order_alerts.dart';
import 'dispatcher_order_card.dart';
import 'order_fact_row.dart';

class IncomingTile extends StatelessWidget {
  const IncomingTile({
    super.key,
    required this.order,
    required this.onOpen,
    required this.originName,
  });
  final Order order;
  final String originName;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final landed = order.status == OrderStatus.awaitingDelivery;
    return DispatcherOrderCard(
      title: order.medicationName,
      subtitle: unitsLabel(order.quantity),
      onTap: onOpen,
      status: _IncomingStatus(landed: landed, status: order.status),
      facts: [
        _IncomingRoute(origin: originName),
        if (landed) const Text('El dron llegó a tu central.'),
        if (order.requiresColdChain)
          const OrderFactRow(
            icon: AppIcons.coldChain,
            label: 'Cadena de frío · 2 a 8 °C',
          ),
        if (order.coldChainAlert ||
            order.statusReason != null ||
            order.receiptRejectedReason != null)
          DispatcherOrderAlerts(order: order),
      ],
      footer: landed
          ? ReceiveOrderButton(
              orderId: order.id,
              landed: true,
              icon: AppIcons.deliveryCode,
            )
          : OutlinedButton(onPressed: onOpen, child: const Text('Ver detalle')),
    );
  }
}

class _IncomingStatus extends StatelessWidget {
  const _IncomingStatus({required this.landed, required this.status});
  final bool landed;
  final OrderStatus status;
  @override
  Widget build(BuildContext context) => StatusPill(
    label: landed
        ? 'Listo para recibir'
        : status == OrderStatus.inFlight
        ? 'En camino'
        : status.label,
    tone: landed ? PillTone.attention : PillTone.neutral,
    subdued: !landed,
    wrapLabel: true,
    leading: landed
        ? Icon(
            AppIcons.incoming,
            size: 18,
            color: StatusPill.colorOf(context, PillTone.attention),
          )
        : DroneGlyph(
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
  );
}

class _IncomingRoute extends StatelessWidget {
  const _IncomingRoute({required this.origin});
  final String origin;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked =
          box.maxWidth < 290 || MediaQuery.textScalerOf(context).scale(16) > 22;
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RouteHubLabel(label: origin),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 3),
              child: RotatedBox(
                quarterTurns: 1,
                child: Icon(AppIcons.forward, size: 18),
              ),
            ),
            const _RouteHubLabel(label: 'Tu central'),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: _RouteHubLabel(label: origin)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(AppIcons.forward, size: 18),
          ),
          const Expanded(child: _RouteHubLabel(label: 'Tu central')),
        ],
      );
    },
  );
}

class _RouteHubLabel extends StatelessWidget {
  const _RouteHubLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(AppIcons.hub, size: 24),
      const SizedBox(width: 8),
      Expanded(child: Text(label)),
    ],
  );
}
