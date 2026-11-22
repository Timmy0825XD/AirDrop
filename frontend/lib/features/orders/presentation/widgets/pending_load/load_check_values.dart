import 'package:flutter/material.dart';
import '../../../../../theme/app_icons.dart';

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
    (icon: AppIcons.medication, text: '${order.medicationName} · $units'),
    if (order.requiresColdChain)
      (icon: AppIcons.coldChain, text: 'Va en nevera, de 2 a 8 °C'),
    if (order.saleType != SaleType.overTheCounter &&
        order.destinationKind == DestinationKind.person)
      (
        icon: AppIcons.document,
        text: '${order.saleType.label}: la fórmula se revisó al autorizar',
      ),
    (
      icon: AppIcons.flight,
      text: a == null
          ? 'Sin dron asignado'
          : 'Dron ${a.identifier} · ${formatKm(a.distanceKm)}',
    ),
    (
      icon: AppIcons.destination,
      text: order.destinationKind == DestinationKind.hub
          ? 'A la central: ${order.address}'
          : 'A domicilio: ${order.address}',
    ),
  ];
}
