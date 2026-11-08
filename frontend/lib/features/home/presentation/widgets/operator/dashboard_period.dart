import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';

/// Los periodos del tablero, los mismos de las métricas del administrador.
class DashboardPeriod extends StatelessWidget {
  const DashboardPeriod({super.key, required this.days, required this.onDays});

  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final d in const [7, 30, 90])
          ChoicePill(
            label: '$d días',
            selected: days == d,
            onTap: () => onDays(d),
          ),
      ],
    );
  }
}

/// "86,4" con coma decimal.
String decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
