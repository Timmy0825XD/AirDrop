import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../data/fleet_models.dart';

/// Estado del dron en la pastilla de siempre: verde disponible, naranja en
/// misión (lo que vuela), marca en mantenimiento y rojo fuera de servicio.
/// Antes "Mantenimiento" pintaba el texto del mismo color que su fondo y
/// no se leía.
class DroneStatusChip extends StatelessWidget {
  const DroneStatusChip({super.key, required this.status});

  final DroneStatus status;

  static PillTone toneOf(DroneStatus status) => switch (status) {
    DroneStatus.available => PillTone.positive,
    DroneStatus.inMission => PillTone.attention,
    DroneStatus.maintenance => PillTone.neutral,
    DroneStatus.outOfService => PillTone.negative,
  };

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: status.label, tone: toneOf(status));
  }
}
