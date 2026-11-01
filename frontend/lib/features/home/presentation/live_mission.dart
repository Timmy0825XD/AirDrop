import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/app_map.dart';
import '../../orders/data/order_models.dart';
import '../../tracking/data/tracking_providers.dart';
import '../../tracking/presentation/widgets/flight_map.dart';
import 'widgets/requester/mission_card.dart';

/// La misión en curso con la telemetría en vivo de un vuelo (el mismo
/// socket del mapa): se abre al mostrarse y se cierra al salir del inicio.
/// La usan el solicitante (su pedido) y el despachador (el primer vuelo de
/// su central). El regreso no se pinta como misión.
class LiveMission extends ConsumerWidget {
  const LiveMission({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trackingProvider(order.id)).telemetry;
    final live = t == null || t.returning ? null : t;
    final points = (order.assignment?.coordinates ?? const <List<double>>[])
        .map(latLngFromGeoJson)
        .toList();
    final drone = live == null ? null : LatLng(live.latitude, live.longitude);
    final routed = points.length >= 2 && drone != null;
    return MissionCard(
      order: order,
      telemetry: live,
      progress: routed
          ? closestRouteIndex(points, drone) / (points.length - 1)
          : null,
      onWatch: () => context.push('/tracking/${order.id}'),
    );
  }
}
