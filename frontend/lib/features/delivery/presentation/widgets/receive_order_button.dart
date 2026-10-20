import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Recibir pedido": abre la pantalla del código (`/delivery/:orderId`).
/// Quien lo pinta decide si corresponde: el pedido espera la entrega y la
/// cuenta es quien recibe.
///
/// Va con `push`, como "Ver vuelo": al entregar, la pantalla vuelve a la de
/// origen, que ya se refresca sola.
class ReceiveOrderButton extends StatelessWidget {
  const ReceiveOrderButton({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => context.push('/delivery/$orderId'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.key_rounded),
      label: const Text('Recibir pedido'),
    );
  }
}
