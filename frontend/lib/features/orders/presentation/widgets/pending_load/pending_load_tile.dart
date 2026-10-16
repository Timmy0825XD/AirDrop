import 'package:flutter/material.dart';

import '../../../../../core/widgets/press_scale.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../order_row_card.dart';
import '../watch_flight_button.dart';

/// Una fila de la bandeja "Pendiente de carga": qué insumo va, en qué dron
/// y qué tan lejos, con el botón para confirmar la carga debajo.
class PendingLoadTile extends StatelessWidget {
  const PendingLoadTile({
    super.key,
    required this.order,
    required this.confirming,
    required this.onConfirm,
    required this.onOpen,
  });

  final Order order;

  /// Esta fila está esperando la respuesta de `confirm-load`.
  final bool confirming;
  final VoidCallback onConfirm;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderRowCard(
          icon: Icons.inventory_outlined,
          tone: colors.primary,
          title: order.medicationName,
          accent: '${order.quantity} und. · ${destinationLabel(order)}',
          detail: routeLine(order.assignment),
          onTap: onOpen,
        ),
        const SizedBox(height: 8),
        _ConfirmButton(
          order: order,
          confirming: confirming,
          onConfirm: onConfirm,
        ),
      ],
    );
  }
}

/// Mientras falta la carga, "Confirmar carga". Ya confirmado, Nest lo deja
/// en la bandeja hasta el primer tick del reloj (unos 2 s): ahí el botón
/// pasa a "Ver vuelo".
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.order,
    required this.confirming,
    required this.onConfirm,
  });

  final Order order;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final child = !order.awaitsLoad
        ? WatchFlightButton(orderId: order.id)
        : FilledButton.icon(
            onPressed: confirming ? null : onConfirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text(confirming ? 'Confirmando…' : 'Confirmar carga'),
          );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: PressScale(key: ValueKey(order.awaitsLoad), child: child),
    );
  }
}
