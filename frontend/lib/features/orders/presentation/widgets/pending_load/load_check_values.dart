import 'package:flutter/material.dart';

import '../../../../inventory/data/inventory_models.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Un punto de la revisión: ícono y texto.
typedef LoadCheckItem = ({IconData icon, String text});

/// Qué revisar antes de despegar. El lote no va: Nest lo descuenta del
/// inventario recién al confirmar la carga.
List<LoadCheckItem> loadChecklist(Order order) {
  final units = order.quantity == 1 ? '1 unidad' : '${order.quantity} unidades';
  final a = order.assignment;
  return [
    (icon: Icons.medication_outlined, text: '${order.medicationName} · $units'),
    if (order.requiresColdChain)
      (icon: Icons.ac_unit_rounded, text: 'Va en nevera, de 2 a 8 °C'),
    if (order.saleType != SaleType.overTheCounter)
      (
        icon: Icons.description_outlined,
        text: '${order.saleType.label}: la fórmula se revisó al autorizar',
      ),
    (
      icon: Icons.flight_rounded,
      text: a == null
          ? 'Sin dron asignado'
          : 'Dron ${a.identifier} · ${formatKm(a.distanceKm)}',
    ),
    (
      icon: Icons.place_outlined,
      text: order.destinationKind == DestinationKind.hub
          ? 'A la central: ${order.address}'
          : 'A domicilio: ${order.address}',
    ),
  ];
}
