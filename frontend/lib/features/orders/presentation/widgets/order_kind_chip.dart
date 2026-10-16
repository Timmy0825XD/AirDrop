import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../data/order_models.dart';

/// Urgencia (rojo) o programado (marca), en la misma pastilla del estado.
class OrderKindChip extends StatelessWidget {
  const OrderKindChip({super.key, required this.missionType});

  final MissionType missionType;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: missionType.label,
      tone: missionType == MissionType.emergency
          ? PillTone.negative
          : PillTone.neutral,
    );
  }
}
