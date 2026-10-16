import 'package:flutter/material.dart';

import '../../../data/order_models.dart';
import '../../order_format.dart';
import 'detail_section.dart';

/// El dron y la ruta que el motor de decisión reservó al autorizar.
class OrderAssignmentCard extends StatelessWidget {
  const OrderAssignmentCard({
    super.key,
    required this.assignment,
    this.loadConfirmedAt,
  });

  final OrderAssignment assignment;

  /// Si ya se confirmó la carga, cuándo.
  final DateTime? loadConfirmedAt;

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    return DetailSection(
      title: 'Dron y ruta asignados',
      icon: Icons.flight_takeoff_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailLine(label: 'Dron', value: '${a.identifier} · ${a.modelName}'),
          DetailLine(
            label: 'Ruta',
            value:
                '${formatKm(a.distanceKm)} a ${a.altitudeM.round()} m de '
                'altitud',
          ),
          DetailLine(
            label: 'Carga',
            value: loadConfirmedAt == null
                ? 'Falta confirmarla'
                : 'Confirmada ${formatBogota(loadConfirmedAt)}',
          ),
        ],
      ),
    );
  }
}
