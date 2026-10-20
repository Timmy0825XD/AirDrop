import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../delivery/presentation/widgets/receive_order_button.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../orders/presentation/widgets/order_status_chip.dart';
import '../data/tracking_providers.dart';
import 'widgets/flight_card.dart';
import 'widgets/flight_map.dart';
import 'widgets/flight_notice.dart';

/// El vuelo de un pedido en vivo (`/tracking/:orderId`).
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
    final role = ref.watch(authControllerProvider).value?.user?.role;
    final t = flight.telemetry;
    final canReceive =
        role == UserRole.requester &&
        (t?.arrived ?? false) &&
        flight.status == OrderStatus.awaitingDelivery;
    return Scaffold(
      appBar: AppBar(
        // Se abre con `push` desde las listas; si se llegó directo, la
        // flecha lleva al inicio en vez de dejar la pantalla sin salida.
        leading: BackButton(onPressed: () => SectionHeader.backOrHome(context)),
        title: Text(order?.medicationName ?? 'Vuelo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlightMap(
              route: order?.assignment?.coordinates ?? const [],
              drone: t == null ? null : LatLng(t.latitude, t.longitude),
            ),
          ),
          _FlightPanel(
            state: flight,
            receive: canReceive ? ReceiveOrderButton(orderId: orderId) : null,
          ),
        ],
      ),
    );
  }
}

/// La parte de abajo: estado, aviso, "Recibir pedido" si aplica y ficha.
class _FlightPanel extends StatelessWidget {
  const _FlightPanel({required this.state, this.receive});

  final TrackingState state;
  final Widget? receive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.status case final status?) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OrderStatusChip(status: status),
                  ),
                  const SizedBox(height: 12),
                ],
                FlightNotice(state: state),
                if (receive case final button?) ...[
                  button,
                  const SizedBox(height: 12),
                ],
                if (state.telemetry case final t?) FlightCard(telemetry: t),
              ],
            ),
    );
  }
}
