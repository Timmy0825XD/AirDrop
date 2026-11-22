import 'package:flutter/material.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../dispatcher_order_alerts.dart';
import '../dispatcher_order_card.dart';
import '../order_fact_row.dart';
import '../watch_flight_button.dart';

class PendingLoadTile extends StatelessWidget {
  const PendingLoadTile({
    super.key,
    required this.order,
    required this.confirming,
    required this.onConfirm,
    required this.onOpen,
  });
  final Order order;
  final bool confirming;
  final VoidCallback onConfirm, onOpen;
  @override
  Widget build(BuildContext context) => DispatcherOrderCard(
    title: order.medicationName,
    subtitle:
        '${unitsLabel(order.quantity)} · ${order.destinationKind == DestinationKind.hub ? 'Para otra central' : 'Para una persona'}',
    onTap: onOpen,
    status: StatusPill(
      label: order.awaitsLoad ? 'Espera la carga' : 'Carga confirmada',
      tone: order.awaitsLoad ? PillTone.attention : PillTone.positive,
      wrapLabel: true,
      leading: Icon(
        AppIcons.orders,
        size: 18,
        color: StatusPill.colorOf(
          context,
          order.awaitsLoad ? PillTone.attention : PillTone.positive,
        ),
      ),
    ),
    facts: [_LoadFacts(order: order)],
    dividedFooter: true,
    footer: _LoadAction(tile: this),
  );
}

class _LoadFacts extends StatelessWidget {
  const _LoadFacts({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    final drone = order.assignment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderFactRow(
          icon: AppIcons.drone,
          label: 'Dron asignado',
          value: drone == null
              ? 'Sin asignar'
              : '${drone.modelName} ${drone.identifier}',
        ),
        const SizedBox(height: 12),
        OrderFactRow(
          icon: AppIcons.coldChain,
          label: 'Conservación',
          value: order.requiresColdChain
              ? 'Cadena de frío · 2 a 8 °C'
              : 'Sin cadena de frío',
        ),
        const SizedBox(height: 12),
        OrderFactRow(
          icon: AppIcons.tag,
          label: 'Lote',
          value: order.dispatchedLot ?? 'Se confirma al revisar la carga',
        ),
        if (order.coldChainAlert || order.statusReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DispatcherOrderAlerts(order: order),
          ),
      ],
    );
  }
}

class _LoadAction extends StatelessWidget {
  const _LoadAction({required this.tile});
  final PendingLoadTile tile;
  @override
  Widget build(BuildContext context) {
    if (!tile.order.awaitsLoad) {
      return WatchFlightButton(orderId: tile.order.id, icon: AppIcons.flight);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: tile.confirming ? null : tile.onConfirm,
          child: Text(
            tile.confirming ? 'Confirmando…' : 'Revisar y cargar',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'El vuelo inicia después de confirmar la carga.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(onPressed: tile.onOpen, child: const Text('Ver pedido')),
      ],
    );
  }
}
