import 'package:flutter/material.dart';

import '../../data/hub_models.dart';
import 'hub_labels.dart';

/// Estado de la central en una píldora. Verde para activa, error para
/// suspendida: el color no es decorativo, distingue de un vistazo si la
/// central puede operar.
class HubStatusChip extends StatelessWidget {
  const HubStatusChip({super.key, required this.status});

  final HubStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status.isActive
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        HubLabels.status(status),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
