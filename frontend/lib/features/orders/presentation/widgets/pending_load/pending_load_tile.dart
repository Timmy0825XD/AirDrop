import 'package:flutter/material.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../order_row_card.dart';
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
  Widget build(BuildContext context) => OrderRowCard(
    icon: AppIcons.medication,
    tone: Theme.of(context).colorScheme.primary,
    title: order.medicationName,
    accent: '${unitsLabel(order.quantity)} · ${destinationLabel(order)}',
    detail: routeLine(order.assignment),
    onTap: onOpen,
    pill: StatusPill(
      label: order.awaitsLoad ? 'Espera la carga' : 'Carga confirmada',
      tone: order.awaitsLoad ? PillTone.attention : PillTone.positive,
    ),
    footer: _LoadAction(tile: this),
    children: [
      if (order.requiresColdChain)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Cadena de frío · 2 a 8 °C'),
        ),
    ],
  );
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
