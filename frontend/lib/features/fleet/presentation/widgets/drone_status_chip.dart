import 'package:flutter/material.dart';

import '../../data/fleet_models.dart';

/// Estado del dron en una píldora. Verde para disponible, cyan de marca
/// para en misión, neutro para mantenimiento y error para fuera de
/// servicio: el color distingue de un vistazo si el dron se puede usar.
class DroneStatusChip extends StatelessWidget {
  const DroneStatusChip({super.key, required this.status});

  final DroneStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Mantenimiento no es ni bueno ni malo: usa el color del texto para
    // no competir con el verde de "Disponible" ni el cyan de "En misión".
    final color = switch (status) {
      DroneStatus.available => scheme.tertiary,
      DroneStatus.inMission => scheme.primary,
      DroneStatus.maintenance => scheme.onSurface,
      DroneStatus.outOfService => scheme.error,
    };
    final alpha = status == DroneStatus.maintenance ? 0.62 : 0.14;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
