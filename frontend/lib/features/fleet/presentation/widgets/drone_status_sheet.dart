import 'package:flutter/material.dart';
import '../../../../core/widgets/action_list.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/drone_glyph.dart';
import '../../../../core/widgets/menu_list.dart';
import '../../../../theme/app_icons.dart';
import '../../data/fleet_models.dart';
import 'drone_status_chip.dart';

typedef DroneActions = ({
  VoidCallback toggleColdCompartment,
  VoidCallback setAvailable,
  VoidCallback sendToMaintenance,
  VoidCallback putOutOfService,
  VoidCallback viewHistory,
});

Future<void> showDroneStatusSheet(
  BuildContext context, {
  required Drone drone,
  required DroneActions actions,
}) => showAppSheet<void>(
  context,
  builder: (_) => DroneStatusSheet(drone: drone, actions: actions),
);

class DroneStatusSheet extends StatelessWidget {
  const DroneStatusSheet({
    super.key,
    required this.drone,
    required this.actions,
  });
  final Drone drone;
  final DroneActions actions;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(drone: drone),
          const SizedBox(height: 24),
          if (!drone.status.isOperable)
            const Text(
              'Este dron no admite cambios de estado ni de equipamiento.',
            )
          else ...[
            Text(
              'Estado y mantenimiento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ActionList(items: _maintenanceActions(context, drone, actions)),
            const SizedBox(height: 24),
            Text('Equipamiento', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ActionList(
              items: [
                _sheetItem(
                  context,
                  AppIcons.coldChain,
                  drone.coldCompartment
                      ? 'Quitar el compartimento de frío'
                      : 'Instalar el compartimento de frío',
                  drone.coldCompartment
                      ? 'Recupera 1 kg de carga útil.'
                      : 'Para insumos refrigerados. Resta 1 kg de carga útil.',
                  actions.toggleColdCompartment,
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.drone});
  final Drone drone;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DroneGlyph(color: Theme.of(context).colorScheme.onSurface, size: 32),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drone.identifier,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            DroneStatusChip(status: drone.status),
          ],
        ),
      ),
    ],
  );
}

List<MenuItem> _maintenanceActions(
  BuildContext context,
  Drone drone,
  DroneActions actions,
) => [
  if (drone.status.isOutOfFleet && drone.status != DroneStatus.grounded)
    _sheetItem(
      context,
      AppIcons.check,
      'Marcar disponible',
      'Vuelve a la flota y cierra el periodo de taller.',
      actions.setAvailable,
    ),
  if (drone.status != DroneStatus.maintenance)
    _sheetItem(
      context,
      AppIcons.maintenance,
      'Enviar a mantenimiento',
      'Temporal, con motivo y fecha estimada.',
      actions.sendToMaintenance,
    ),
  if (drone.status != DroneStatus.outOfService)
    _sheetItem(
      context,
      AppIcons.power,
      'Dejar fuera de servicio',
      'Sin fecha de regreso.',
      actions.putOutOfService,
    ),
  _sheetItem(
    context,
    AppIcons.history,
    'Ver historial de taller',
    'Mantenimientos y salidas de la flota.',
    actions.viewHistory,
  ),
];

MenuItem _sheetItem(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  VoidCallback action,
) => MenuItem(
  icon: icon,
  title: title,
  subtitle: subtitle,
  onTap: () {
    Navigator.pop(context);
    action();
  },
);
