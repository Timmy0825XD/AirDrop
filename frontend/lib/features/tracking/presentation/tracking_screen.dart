import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/app_map.dart';
import '../../../core/widgets/map_sheet.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../delivery/presentation/widgets/receive_order_button.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import '../../orders/presentation/widgets/order_detail/cold_chain_banner.dart';
import '../../orders/presentation/widgets/order_status_chip.dart';
import '../data/telemetry_models.dart';
import '../data/tracking_providers.dart';
import 'widgets/flight_card.dart';
import 'widgets/flight_hud.dart';
import 'widgets/flight_map.dart';
import 'widgets/flight_notice.dart';
import 'widgets/flight_timeline.dart';

/// El vuelo de un pedido en vivo (`/tracking/:orderId`): el mapa a
/// pantalla completa con la barra "En vivo" y el panel de altitud y rumbo
/// arriba; en la hoja de abajo, el medicamento con su estado, el aviso,
/// "Recibir pedido" si aplica, la telemetría con el avance por la ruta y
/// la línea de tiempo del vuelo.
///
/// Del pedido (`GET /orders/:id`) saca el título y la ruta; de la
/// telemetría (GET y luego socket) el punto del dron y la ficha. Al salir
/// de la pantalla el socket se cierra. Con el dron en destino, el
/// solicitante tiene "Recibir pedido" (el despachador de origen solo mira:
/// un traslado lo recibe la central de destino).
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId)).value;
    final flight = ref.watch(trackingProvider(orderId));
    // La ruta de regreso se calcula cuando el dron empieza a volver: ahí se
    // vuelve a leer el pedido para traerla.
    ref.listen(trackingProvider(orderId), (previous, next) {
      final nowBack = next.telemetry?.returning ?? false;
      final wasBack = previous?.telemetry?.returning ?? false;
      if (nowBack && !wasBack) ref.invalidate(orderDetailProvider(orderId));
    });
    final role = ref.watch(authControllerProvider).value?.user?.role;
    final t = flight.telemetry;
    // El código se ve desde el despegue; el estado del socket manda sobre
    // el del detalle, que se lee una sola vez.
    final status = flight.status ?? order?.status;
    final canReceive =
        role == UserRole.requester &&
        (status == OrderStatus.inFlight ||
            status == OrderStatus.awaitingDelivery ||
            (status == OrderStatus.pendingLoad &&
                order?.loadConfirmedAt != null));
    // El solicitante ve la ida y la entrega; el regreso del dron (con o
    // sin paquete) solo lo ven el despachador y el operador.
    final hideReturn =
        role == UserRole.requester &&
        ((t?.returning ?? false) ||
            status == OrderStatus.delivered ||
            status == OrderStatus.returning ||
            status == OrderStatus.returned);
    final drone = t == null || hideReturn
        ? null
        : LatLng(t.latitude, t.longitude);
    final assignment = order?.assignment;
    final back =
        (t?.returning ?? false) && (assignment?.hasReturnRoute ?? false);
    final line = back
        ? assignment!.returnCoordinates
        : assignment?.coordinates ?? const <List<double>>[];
    final points = line.map(latLngFromGeoJson).toList();
    final split = closestRouteIndex(points, drone);
    final routed = points.length >= 2 && drone != null;
    final coldAlert =
        (order?.coldChainAlert ?? false) ||
        flight.alert?.kind == FlightAlertKind.coldChain;
    return MapSheetScaffold(
      title: order?.medicationName ?? 'Vuelo',
      // Se abre con `push` desde las listas; si se llegó directo, volver
      // lleva al inicio en vez de dejar la pantalla sin salida.
      onBack: () => SectionHeader.backOrHome(context),
      trailing: status == null ? null : OrderStatusChip(status: status),
      titleBar: t == null
          ? null
          : FlightLiveBar(
              connected: flight.connected,
              identifier: t.identifier,
              latencyMs: t.vitals?.latencyMs,
            ),
      hud: drone == null
          ? null
          : FlightHud(
              altitudeM: t!.altitudeM,
              headingDeg: routed
                  ? routeHeading(points, split) * 180 / math.pi
                  : null,
            ),
      map: (sheetHeight) => FlightMap(
        route: line,
        returnLeg: back,
        drone: drone,
        sheetHeight: sheetHeight,
      ),
      sheet: flight.loading
          ? const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ]
          : [
              if (order != null && status != null)
                _SheetTitle(name: order.medicationName, status: status),
              FlightNotice(state: flight, showReturn: !hideReturn),
              if (coldAlert && role != UserRole.requester)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ColdChainBanner(at: order?.coldChainAlertAt),
                ),
              if (canReceive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ReceiveOrderButton(
                    orderId: orderId,
                    landed: t?.arrived ?? false,
                  ),
                ),
              if (t != null && !hideReturn)
                RiseIn(
                  child: FlightCard(
                    telemetry: t,
                    progress: routed ? split / (points.length - 1) : null,
                  ),
                ),
              const SizedBox(height: 18),
              FlightTimeline(order: order, status: status, telemetry: t),
            ],
    );
  }
}

/// El medicamento y su estado, arriba de la hoja.
class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.name, required this.status});

  final String name;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          OrderStatusChip(status: status),
        ],
      ),
    );
  }
}
