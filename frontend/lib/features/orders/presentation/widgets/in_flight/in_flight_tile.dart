import 'package:flutter/material.dart';

import '../../../../../core/widgets/row_action_button.dart';
import '../../../../../core/widgets/status_card.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../auth/presentation/widgets/drone_glyph.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Tarjeta de un vuelo en curso: el dron, qué lleva, a dónde y qué tan
/// lejos, el estado y "Ver vuelo". En vuelo va en naranja (lo que se
/// mueve); esperando la entrega, en verde (ya llegó).
class InFlightTile extends StatelessWidget {
  const InFlightTile({super.key, required this.order, required this.onWatch});

  final Order order;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final landed = order.status == OrderStatus.awaitingDelivery;
    return StatusCard(
      leading: const _DroneTile(),
      body: _FlightInfo(order: order),
      status: StatusPill(
        label: order.status.label,
        tone: landed ? PillTone.positive : PillTone.attention,
      ),
      action: RowActionButton(label: 'Ver vuelo', onPressed: onWatch),
    );
  }
}

class _DroneTile extends StatelessWidget {
  const _DroneTile();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DroneGlyph(color: colors.secondary, size: 28),
    );
  }
}

class _FlightInfo extends StatelessWidget {
  const _FlightInfo({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.medicationName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${order.quantity} und. · ${destinationLabel(order)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(routeLine(order.assignment), style: muted),
      ],
    );
  }
}
