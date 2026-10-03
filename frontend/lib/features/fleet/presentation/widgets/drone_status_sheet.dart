import 'package:flutter/material.dart';

import '../../data/fleet_models.dart';
import 'drone_status_chip.dart';

/// Abre la hoja de acciones del dron. Cada botón dispara **un** solo
/// endpoint (el plan lo llama "una sola vía por botón, nunca las dos"):
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
    final isAvailable = drone.status == DroneStatus.available;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(drone: drone),
          const Divider(height: 1),
          if (drone.status.isInMission)
            const ListTile(
              title: Text('Un dron en misión no admite cambios de estado.'),
            )
          else ...[
            if (!isAvailable)
              _ActionTile(
                icon: Icons.check_circle_outline,
                title: 'Marcar disponible',
                subtitle: 'Deja el dron listo y borra el mantenimiento.',
                onPressed: onSetAvailable,
              ),
            _ActionTile(
              icon: Icons.build_outlined,
              title: 'Poner en mantenimiento',
              subtitle: 'Motivo y fecha estimada opcionales.',
              onPressed: onPutInMaintenance,
            ),
            _ActionTile(
              icon: Icons.handyman_outlined,
              title: 'Registrar mantenimiento',
              subtitle: 'Motivo y fecha obligatorios: queda fuera de servicio.',
              onPressed: onRegisterMaintenance,
            ),
          ],
        ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(drone.identifier, style: theme.textTheme.titleLarge),
          ),
          DroneStatusChip(status: drone.status),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        // Se cierra primero: los callbacks abren el diálogo de motivo y
        // fecha sobre la pantalla, no sobre la hoja.
        Navigator.pop(context);
        onPressed();
      },
    );
  }
}
