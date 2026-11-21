import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/route_line.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../orders/data/order_models.dart';
import '../../../../orders/presentation/widgets/order_status_chip.dart';
import '../../../../tracking/data/tracking_providers.dart';
import '../../../../tracking/data/telemetry_models.dart';
import '../../../../tracking/presentation/widgets/flight_map.dart';

class RequesterCurrentOrder extends ConsumerWidget {
  const RequesterCurrentOrder({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flight = order.hasFlight
        ? ref.watch(trackingProvider(order.id))
        : null;
    final current = order.copyWith(status: flight?.status ?? order.status);
    final snapshot = flight?.telemetry;
    final telemetry = snapshot == null || snapshot.returning ? null : snapshot;
    final progress = _routeProgress(order, telemetry);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrderHeading(order: current),
              if (current.hasFlight &&
                  current.status != OrderStatus.returning) ...[
                const SizedBox(height: 20),
                _RouteStrip(progress: progress),
              ],
              const SizedBox(height: 16),
              _OrderAction(order: current, telemetry: telemetry),
            ],
          ),
        ),
        if (current.deliveryCodeVisible)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/delivery/${order.id}'),
              child: Text(
                current.status == OrderStatus.awaitingDelivery
                    ? 'Recibir con el código'
                    : 'Ver código de entrega',
              ),
            ),
          ),
      ],
    );
  }
}

double? _routeProgress(Order order, Telemetry? telemetry) {
  if (telemetry == null) return null;
  final points = (order.assignment?.coordinates ?? const <List<double>>[])
      .map(latLngFromGeoJson)
      .toList();
  if (points.length < 2) return null;
  return closestRouteIndex(
        points,
        LatLng(telemetry.latitude, telemetry.longitude),
      ) /
      (points.length - 1);
}

class _OrderHeading extends StatelessWidget {
  const _OrderHeading({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StatusPill(
        label: OrderStatusChip.requesterLabel(order.status),
        tone: order.status == OrderStatus.inFlight
            ? PillTone.neutral
            : OrderStatusChip.toneOf(order.status),
      ),
      const SizedBox(height: 12),
      Text(
        order.medicationName,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        '${order.quantity} ${order.quantity == 1 ? 'unidad' : 'unidades'}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _RouteStrip extends StatelessWidget {
  const _RouteStrip({required this.progress});
  final double? progress;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        AppIcons.hub,
        size: 26,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: RouteLine(
          endLabel: 'Tu ubicación',
          progress: progress,
          hover: false,
        ),
      ),
      const SizedBox(width: 10),
      Icon(
        AppIcons.destination,
        size: 26,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ],
  );
}

class _OrderAction extends StatelessWidget {
  const _OrderAction({required this.order, required this.telemetry});
  final Order order;
  final Telemetry? telemetry;

  @override
  Widget build(BuildContext context) {
    final eta = order.status == OrderStatus.inFlight
        ? telemetry?.etaMinutes
        : null;
    final tracking = order.hasFlight && order.status != OrderStatus.returning;
    final message = order.status == OrderStatus.awaitingDelivery
        ? 'Tu pedido llegó'
        : eta != null
        ? 'Llega en $eta min'
        : order.status == OrderStatus.inFlight
        ? 'En camino a tu ubicación'
        : OrderStatusChip.requesterLabel(order.status);
    return LayoutBuilder(
      builder: (context, box) {
        final button = OutlinedButton(
          onPressed: () => context.push(
            tracking ? '/tracking/${order.id}' : '/orders/${order.id}',
          ),
          child: Text(tracking ? 'Ver vuelo' : 'Ver pedido'),
        );
        final label = Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        );
        if (box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [label, const SizedBox(height: 12), button],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    );
  }
}
