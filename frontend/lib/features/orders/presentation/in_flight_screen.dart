import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/in_flight/in_flight_tile.dart';
import 'widgets/order_tray.dart';

/// Bandeja "Vuelos en curso" del despachador (`GET /orders/in-flight`).
///
/// Al despegar, el pedido sale de pending-load; aquí sigue mientras va en
/// vuelo o espera la entrega, y "Ver vuelo" abre el mapa. Sin socket: se
/// refresca cada 10 s como las demás bandejas.
class InFlightScreen extends ConsumerWidget {
  const InFlightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<Order>(
      title: 'Vuelos en curso',
      idleSubtitle: 'Lo que salió de tu central',
      countLabel: (n) => n == 1 ? '1 dron en el aire' : '$n drones en el aire',
      rows: ref.watch(inFlightProvider),
      onRefresh: () => ref.invalidate(inFlightProvider),
      emptyIcon: Icons.flight_land_rounded,
      emptyText: 'Ningún dron de tu central está volando ahora.',
      keyOf: (order) => order.id,
      itemBuilder: (context, order) => InFlightTile(
        order: order,
        // `push` y no `go`: el mapa queda encima y "volver" regresa aquí.
        onWatch: () => context.push('/tracking/${order.id}'),
      ),
    );
  }
}
