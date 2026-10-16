import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../orders/data/order_providers.dart';
import '../../orders/presentation/widgets/order_status_chip.dart';
import '../data/tracking_providers.dart';
import 'widgets/flight_card.dart';
import 'widgets/flight_map.dart';
import 'widgets/flight_notice.dart';

/// El vuelo de un pedido en vivo (`/tracking/:orderId`).
///
/// Del pedido (`GET /orders/:id`) saca el título y la ruta; de la
/// telemetría (GET y luego socket) el punto del dron y la ficha. Al salir
/// de la pantalla el socket se cierra.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId)).asData?.value;
    final flight = ref.watch(trackingProvider(orderId));
    final t = flight.telemetry;
    return Scaffold(
      appBar: AppBar(title: Text(order?.medicationName ?? 'Vuelo')),
      body: Column(
        children: [
          Expanded(
            child: FlightMap(
              route: order?.assignment?.coordinates ?? const [],
              drone: t == null ? null : LatLng(t.latitude, t.longitude),
            ),
          ),
          _FlightPanel(state: flight),
        ],
      ),
    );
  }
}

/// La parte de abajo: estado, aviso y ficha.
class _FlightPanel extends StatelessWidget {
  const _FlightPanel({required this.state});

  final TrackingState state;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.status case final status?) ...[
                  OrderStatusChip(status: status),
                  const SizedBox(height: 12),
                ],
                FlightNotice(state: state),
                if (state.telemetry case final t?) FlightCard(telemetry: t),
              ],
            ),
    );
  }
}
