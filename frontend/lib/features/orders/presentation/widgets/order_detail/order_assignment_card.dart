import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// El dron y la ruta que el motor de decisión reservó al autorizar. Va en
/// naranja: es lo que vuela.
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
      tone: Theme.of(context).colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailLine(label: 'Dron', value: '${a.identifier} · ${a.modelName}'),
          DetailLine(
            label: 'Ruta',
            value: '${formatKm(a.distanceKm)} a ${a.altitudeM.round()} m',
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
