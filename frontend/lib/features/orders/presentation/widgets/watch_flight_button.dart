import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Ver vuelo": abre el mapa en vivo del pedido (`/tracking/:orderId`).
/// Quien lo pinta decide si corresponde (ver `Order.hasFlight`).
///
/// Va con `push`: el mapa queda encima de la pantalla de origen y "volver"
/// regresa a ella. Con `go` el mapa quedaba solo y sin flecha de volver.
class WatchFlightButton extends StatelessWidget {
  const WatchFlightButton({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => context.push('/tracking/$orderId'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.map_outlined),
      label: const Text('Ver vuelo'),
    );
  }
}
