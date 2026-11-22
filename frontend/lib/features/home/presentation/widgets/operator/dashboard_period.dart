import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';

/// El selector compacto del diseño aprobado conserva los mismos periodos.
class DashboardPeriod extends StatelessWidget {
  const DashboardPeriod({super.key, required this.days, required this.onDays});

  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Cambiar periodo',
      initialValue: days,
      onSelected: onDays,
      itemBuilder: (_) => [
        for (final value in [7, 30, 90])
          PopupMenuItem(value: value, child: Text('Últimos $value días')),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Últimos $days días',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 6),
            const RotatedBox(
              quarterTurns: 1,
              child: Icon(AppIcons.next, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// "86,4" con coma decimal.
String decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
