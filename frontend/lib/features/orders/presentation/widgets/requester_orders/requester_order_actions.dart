import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/drone_glyph.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../../../tracking/data/telemetry_models.dart';

class RequesterOrderActions extends StatelessWidget {
  const RequesterOrderActions({
    super.key,
    required this.order,
    required this.telemetry,
  });
  final Order order;
  final Telemetry? telemetry;

  @override
  Widget build(BuildContext context) {
    final eta =
        order.status == OrderStatus.inFlight && telemetry?.returning != true
        ? telemetry?.etaMinutes
        : null;
    final title = order.status == OrderStatus.awaitingDelivery
        ? 'Tu pedido llegó'
        : eta != null
        ? (eta > 0 ? 'Llega en $eta min' : 'Está por llegar')
        : order.status == OrderStatus.inFlight
        ? 'En camino a tu ubicación'
        : 'Tu envío está por salir';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _FlightButtons(order: order),
      ],
    );
  }
}

class _FlightButtons extends StatelessWidget {
  const _FlightButtons({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final flight = FilledButton.icon(
        onPressed: () => context.push('/tracking/${order.id}'),
        icon: DroneGlyph(
          color: Theme.of(context).colorScheme.onPrimary,
          size: 20,
        ),
        label: const Text('Ver vuelo'),
      );
      final code = OutlinedButton.icon(
        onPressed: () => context.push('/delivery/${order.id}'),
        icon: const Icon(AppIcons.deliveryCode, size: 20),
        label: const Text('Ver código'),
      );
      if (box.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            flight,
            if (order.deliveryCodeVisible) ...[
              const SizedBox(height: 10),
              code,
            ],
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: flight),
          if (order.deliveryCodeVisible) ...[
            const SizedBox(width: 10),
            Expanded(child: code),
          ],
        ],
      );
    },
  );
}
