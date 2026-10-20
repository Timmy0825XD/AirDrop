import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Abre la pantalla del código de entrega (`/delivery/:orderId`). Mientras
/// el dron vuela dice "Ver código de entrega"; con el dron en tierra
/// ([landed]), "Recibir pedido". Quien lo pinta decide si corresponde: la
/// cuenta es quien recibe y `Order.deliveryCodeVisible`.
///
/// Va con `push`, como "Ver vuelo": al entregar, la pantalla vuelve a la de
/// origen, que ya se refresca sola.
class ReceiveOrderButton extends StatelessWidget {
  const ReceiveOrderButton({
    super.key,
    required this.orderId,
    required this.landed,
  });

  final String orderId;
  final bool landed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => context.push('/delivery/$orderId'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(landed ? Icons.key_rounded : Icons.pin_outlined),
      label: Text(landed ? 'Recibir pedido' : 'Ver código de entrega'),
    );
  }
}
