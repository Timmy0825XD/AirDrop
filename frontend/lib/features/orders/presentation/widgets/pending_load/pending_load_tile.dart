import 'package:flutter/material.dart';

import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Una fila de la bandeja "Pendiente de carga": qué insumo va, en qué dron
/// y qué tan lejos, con el botón para confirmar la carga.
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(order.medicationName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                _routeLine(order.assignment),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _ConfirmButton(
                order: order,
                confirming: confirming,
                onConfirm: onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Dron D-01 · 4,2 km · 100 m". Sin asignación no debería llegar aquí,
/// pero si llega no se cae.
String _routeLine(OrderAssignment? a) {
  if (a == null) return 'Sin dron asignado';
  return 'Dron ${a.identifier} · ${formatKm(a.distanceKm)} · '
      '${a.altitudeM.round()} m';
}

/// Ya confirmado, Nest lo deja en la bandeja hasta el primer tick del reloj
/// (unos 2 s), cuando pasa a "En vuelo": el botón dice "Despegando…".
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
    final waiting = order.awaitsLoad;
    return FilledButton.icon(
      onPressed: confirming || !waiting ? null : onConfirm,
      icon: const Icon(Icons.check_rounded),
      label: Text(
        !waiting
            ? 'Despegando…'
            : (confirming ? 'Confirmando…' : 'Confirmar carga'),
      ),
    );
  }
}
