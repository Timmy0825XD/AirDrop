import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Ver vuelo": abre el mapa en vivo del pedido (`/tracking/:orderId`).
/// Quien lo pinta decide si corresponde (ver `Order.hasFlight`).
class WatchFlightButton extends StatelessWidget {
  const WatchFlightButton({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => context.go('/tracking/$orderId'),
      icon: const Icon(Icons.map_outlined),
      label: const Text('Ver vuelo'),
    );
  }
}
