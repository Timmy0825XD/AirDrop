import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/error_banner.dart';
import '../../hubs/data/hub_models.dart';
import '../data/fleet_models.dart';
import '../data/fleet_providers.dart';
import 'widgets/drone_status_sheet.dart';
import 'widgets/drone_tile.dart';
import 'widgets/fleet_hub_selector.dart';
import 'widgets/maintenance_form_dialog.dart';

/// Flota del operador: elige una de sus centrales y lista sus drones.
/// De la central elegida sale también el `hubId` del alta, porque
/// `POST /fleet/drones` lo exige y el operador puede tener varias.
class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flota')),
      body: const _FleetBody(),
      floatingActionButton: const _NewDroneButton(),
    );
  }
}

/// Si el operador no tiene centrales asignadas, ese es el mensaje: la
/// lista de drones nunca se consulta sin una central elegida.
class _FleetBody extends ConsumerWidget {
  const _FleetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(assignedHubsProvider);

    return hubs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FleetMessage(message: '$error'),
      data: (rows) => rows.isEmpty
          ? const _FleetMessage(message: 'No tienes centrales asignadas.')
          : _FleetPane(hubs: rows),
    );
  }
}

/// Selector, aviso de central suspendida y listado de drones.
class _FleetPane extends ConsumerWidget {
  const _FleetPane({required this.hubs});

  final List<Hub> hubs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    if (hub == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FleetHubSelector(
            hubs: hubs,
            selectedId: hub.id,
            onChanged: (id) =>
                ref.read(fleetHubProvider.notifier).select(id),
          ),
        ),
        if (!hub.isActive)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ErrorBanner(message: 'La central está suspendida.'),
          ),
        const Expanded(child: _DroneList()),
      ],
    );
  }
}

/// Drones de la central efectiva. Un dron en misión entra sin acciones:
/// Nest responde `409` si se intenta cambiar su estado.
class _DroneList extends ConsumerWidget {
  const _DroneList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drones = ref.watch(dronesProvider);
    final models = ref.watch(fleetModelsProvider).asData?.value;

    return drones.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FleetMessage(message: '$error'),
      data: (rows) => rows.isEmpty
          ? const _FleetMessage(message: 'Aún no hay drones en esta central.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final drone = rows[index];
                return DroneTile(
                  drone: drone,
                  modelName: _modelName(models, drone.droneModelId),
                  onActions: drone.status.isInMission
                      ? null
                      : () => _openDroneActions(context, ref, drone),
                );
              },
            ),
    );
  }
}

/// El alta solo se ofrece con una central elegida y activa: Nest responde
/// `403 La central está suspendida.` en cualquier otro caso.
class _NewDroneButton extends ConsumerWidget {
  const _NewDroneButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    final canCreate = hub?.isActive ?? false;

    return FloatingActionButton.extended(
      onPressed: canCreate ? () => context.go('/fleet/new') : null,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo dron'),
    );
  }
}

class _FleetMessage extends StatelessWidget {
  const _FleetMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Nombre del modelo resuelto contra `GET /fleet/models`, porque el dron
/// solo trae el `droneModelId`.
String? _modelName(List<DroneModel>? models, String droneModelId) {
  if (models == null) return null;
  for (final model in models) {
    if (model.id == droneModelId) return model.name;
  }
  return null;
}

/// Hoja de acciones. Cada botón dispara un endpoint distinto, nunca los
/// dos (`PLAN.md`, paso e).
void _openDroneActions(BuildContext context, WidgetRef ref, Drone drone) {
  showDroneStatusSheet(
    context,
    drone: drone,
    onSetAvailable: () => _patchStatus(
      context,
      ref,
      drone.id,
      const UpdateDroneStatusRequest(status: DroneStatus.available),
      'Dron disponible.',
    ),
    onPutInMaintenance: () => _askMaintenance(context, ref, drone),
    onRegisterMaintenance: () => _registerMaintenance(context, ref, drone),
  );
}

/// `PATCH .../status` con `maintenance`: motivo y fecha opcionales, así
/// que el diálogo puede arrancar con lo que el dron ya traía.
Future<void> _askMaintenance(
  BuildContext context,
  WidgetRef ref,
  Drone drone,
) async {
  final input = await showMaintenanceDialog(
    context,
    mandatory: false,
    initialReason: drone.maintenanceReason ?? '',
    initialDate: drone.maintenanceUntil ?? '',
  );
  if (input == null || !context.mounted) return;

  await _patchStatus(
    context,
    ref,
    drone.id,
    UpdateDroneStatusRequest(
      status: DroneStatus.maintenance,
      reason: input.reason,
      estimatedEndDate: input.estimatedEndDate,
    ),
    'Dron en mantenimiento.',
  );
}

/// `POST .../maintenance`: motivo y fecha obligatorios y el dron queda
/// `out_of_service`.
Future<void> _registerMaintenance(
  BuildContext context,
  WidgetRef ref,
  Drone drone,
) async {
  final input = await showMaintenanceDialog(
    context,
    mandatory: true,
    initialReason: drone.maintenanceReason ?? '',
    initialDate: drone.maintenanceUntil ?? '',
  );
  if (input == null || !context.mounted) return;

  try {
    await ref.read(registerMaintenanceProvider.notifier).register(
          drone.id,
          RegisterMaintenanceRequest(
            reason: input.reason,
            estimatedEndDate: input.estimatedEndDate,
          ),
        );
    if (context.mounted) {
      showAppSnack(
        context,
        'Mantenimiento registrado: dron fuera de servicio.',
      );
    }
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}

/// Un solo `PATCH` para las vías de disponible y de mantenimiento. Los
/// errores de Nest (409 en misión, 404 del dron) viajan tal cual.
Future<void> _patchStatus(
  BuildContext context,
  WidgetRef ref,
  String droneId,
  UpdateDroneStatusRequest request,
  String doneMessage,
) async {
  try {
    await ref.read(updateDroneStatusProvider.notifier).set(droneId, request);
    if (context.mounted) showAppSnack(context, doneMessage);
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}
