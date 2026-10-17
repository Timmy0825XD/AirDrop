import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../data/fleet_models.dart';
import 'drone_status_chip.dart';

/// Abre la hoja de acciones del dron. Cada opción dispara **un** solo
/// endpoint ("una sola vía por botón, nunca las dos"):
///
/// - Marcar disponible → `PATCH .../status` con `available` (Nest limpia
///   motivo y fecha).
/// - Poner en mantenimiento → `PATCH .../status` con `maintenance` y los
///   campos opcionales.
/// - Registrar mantenimiento → `POST .../maintenance` con motivo y fecha
///   obligatorios; el dron queda `out_of_service`.
///
/// La hoja se cierra antes de invocar el callback, que es quien pide los
/// datos y llama al repositorio.
Future<void> showDroneStatusSheet(
  BuildContext context, {
  required Drone drone,
  required VoidCallback onSetAvailable,
  required VoidCallback onPutInMaintenance,
  required VoidCallback onRegisterMaintenance,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => DroneStatusSheet(
      drone: drone,
      onSetAvailable: onSetAvailable,
      onPutInMaintenance: onPutInMaintenance,
      onRegisterMaintenance: onRegisterMaintenance,
    ),
  );
}

class DroneStatusSheet extends StatelessWidget {
  const DroneStatusSheet({
    super.key,
    required this.drone,
    required this.onSetAvailable,
    required this.onPutInMaintenance,
    required this.onRegisterMaintenance,
  });

  final Drone drone;
  final VoidCallback onSetAvailable;
  final VoidCallback onPutInMaintenance;
  final VoidCallback onRegisterMaintenance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(drone: drone),
            const SizedBox(height: 16),
            if (drone.status != DroneStatus.available)
              _ActionTile(
                icon: Icons.check_circle_outline_rounded,
                tone: colors.tertiary,
                title: 'Marcar disponible',
                subtitle: 'Deja el dron listo y borra el mantenimiento.',
                onPressed: onSetAvailable,
              ),
            _ActionTile(
              icon: Icons.build_outlined,
              tone: colors.primary,
              title: 'Poner en mantenimiento',
              subtitle: 'Motivo y fecha estimada opcionales.',
              onPressed: onPutInMaintenance,
            ),
            _ActionTile(
              icon: Icons.handyman_outlined,
              tone: colors.error,
              title: 'Registrar mantenimiento',
              subtitle: 'Motivo y fecha obligatorios: queda fuera de servicio.',
              onPressed: onRegisterMaintenance,
            ),
          ],
        ),
      ),
    );
  }
}

/// Identificador y estado actual, para no operar a ciegas.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.drone});

  final Drone drone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            drone.identifier,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        DroneStatusChip(status: drone.status),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressScale(
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Icon(icon, color: tone),
            title: Text(title, style: theme.textTheme.titleSmall),
            subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
            onTap: () {
              // Se cierra primero: los callbacks abren la hoja de motivo y
              // fecha sobre la pantalla, no sobre esta.
              Navigator.pop(context);
              onPressed();
            },
          ),
        ),
      ),
    );
  }
}
