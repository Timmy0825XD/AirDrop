import 'package:flutter/material.dart';

import '../../../../../core/widgets/sliding_segmented.dart';

/// Los periodos del tablero, los mismos de las métricas del administrador,
/// en el filtro segmentado de la app.
class DashboardPeriod extends StatelessWidget {
  const DashboardPeriod({super.key, required this.days, required this.onDays});

  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    return SlidingSegmented<int>(
      options: const [
        SegmentOption(7, '7 días'),
        SegmentOption(30, '30 días'),
        SegmentOption(90, '90 días'),
      ],
      selected: days,
      onChanged: onDays,
    );
  }
}

/// "86,4" con coma decimal.
String decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
