import 'package:flutter/material.dart';

import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../data/fleet_models.dart';
import 'drone_status_chip.dart';

/// Lo que se puede hacer con un dron desde "Gestionar". Cada una dispara
/// **un** solo endpoint ("una sola vía por botón, nunca las dos"):
///
/// - [setAvailable] → `PATCH .../status` con `available` (cierra el periodo
///   de taller; Nest limpia motivo y fecha).
/// - [sendToMaintenance] → `POST .../maintenance`: temporal, con motivo y
///   fecha estimada obligatorios.
/// - [putOutOfService] → `PATCH .../status` con `out_of_service` y el
///   motivo: indefinido, sin fecha.
/// - [viewHistory] → el historial de taller.
typedef DroneActions = ({
  VoidCallback setAvailable,
  VoidCallback sendToMaintenance,
  VoidCallback putOutOfService,
  VoidCallback viewHistory,
});

/// Abre la hoja de acciones del dron. La hoja se cierra antes de invocar
/// la acción, que es quien pide los datos y llama al repositorio.
Future<void> showDroneStatusSheet(
  BuildContext context, {
  required Drone drone,
  required DroneActions actions,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => DroneStatusSheet(drone: drone, actions: actions),
  );
}

class DroneStatusSheet extends StatelessWidget {
  const DroneStatusSheet({
    super.key,
    required this.drone,
    required this.actions,
  });

  final Drone drone;
  final DroneActions actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(drone: drone),
            const SizedBox(height: 16),
            _ActionList(status: drone.status, actions: actions),
          ],
        ),
      ),
    );
  }
}

/// Las acciones que aplican al estado: no se ofrece mandar a mantenimiento
/// un dron que ya está ahí, ni marcar disponible uno que ya lo está.
class _ActionList extends StatelessWidget {
  const _ActionList({required this.status, required this.actions});

  final DroneStatus status;
  final DroneActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.isOutOfFleet && status != DroneStatus.grounded)
          _ActionTile(
            icon: Icons.check_circle_outline_rounded,
            tone: colors.tertiary,
            title: 'Marcar disponible',
            subtitle: 'Vuelve a la flota y cierra el periodo de taller.',
            onPressed: actions.setAvailable,
          ),
        if (status != DroneStatus.maintenance)
          _ActionTile(
            icon: Icons.build_outlined,
            tone: colors.primary,
            title: 'Enviar a mantenimiento',
            subtitle:
                'Vuelve a la flota cuando lo marques disponible. '
                'Lleva fecha estimada.',
            onPressed: actions.sendToMaintenance,
          ),
        if (status != DroneStatus.outOfService)
          _ActionTile(
            icon: Icons.block_rounded,
            tone: colors.error,
            title: 'Dejar fuera de servicio',
            subtitle: 'Sin fecha de regreso.',
            onPressed: actions.putOutOfService,
          ),
        _ActionTile(
          icon: Icons.history_rounded,
          tone: colors.onSurfaceVariant,
          title: 'Ver historial de taller',
          subtitle: 'Mantenimientos y salidas de la flota.',
          onPressed: actions.viewHistory,
        ),
      ],
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
