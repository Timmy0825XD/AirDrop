import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_models.dart';
import '../data/fleet_models.dart';
import '../data/fleet_providers.dart';
import 'widgets/drone_status_sheet.dart';
import 'widgets/drone_tile.dart';
import 'widgets/fleet_hub_selector.dart';
import 'widgets/maintenance_sheet.dart';

/// Flota del operador: elige una de sus centrales (chips bajo el
/// encabezado si tiene varias) y lista sus drones. De la central elegida
/// sale también el `hubId` del alta, porque `POST /fleet/drones` lo exige.
class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    final count = ref.watch(dronesProvider).asData?.value.length;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Flota',
            subtitle: hub == null
                ? 'Drones de tus centrales'
                : '${hub.name}${count == null ? '' : ' · ${count == 1 ? '1 dron' : '$count drones'}'}',
            onBack: () => context.go('/home'),
          ),
          const Expanded(child: _FleetBody()),
        ],
      ),
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
    return switch (ref.watch(assignedHubsProvider)) {
      AsyncData(:final value) when value.isEmpty => const MessageView(
        icon: Icons.domain_disabled_outlined,
        message: 'No tienes centrales asignadas.',
      ),
      AsyncData(:final value) => _FleetPane(hubs: value),
      AsyncError(:final error) => MessageView(
        icon: Icons.cloud_off_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
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
        if (hubs.length > 1) ...[
          const SizedBox(height: 16),
          FleetHubSelector(
            hubs: hubs,
            selectedId: hub.id,
            onChanged: (id) => ref.read(fleetHubProvider.notifier).select(id),
          ),
        ],
        if (!hub.isActive)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: ErrorBanner(
              message:
                  'La central está suspendida: sus drones no se pueden '
                  'gestionar hasta que la reactiven.',
            ),
          ),
        Expanded(child: _DroneList(hubActive: hub.isActive)),
      ],
    );
  }
}

/// Drones de la central efectiva. Sin acciones si el dron está en misión
/// (Nest responde 409) o si la central está suspendida (403).
class _DroneList extends ConsumerWidget {
  const _DroneList({required this.hubActive});

  final bool hubActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(fleetModelsProvider).asData?.value;
    return switch (ref.watch(dronesProvider)) {
      AsyncData(:final value) when value.isEmpty => const MessageView(
        icon: Icons.flight_land_rounded,
        message: 'Aún no hay drones en esta central.',
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final drone = value[i];
          return RiseIn(
            key: ValueKey(drone.id),
            delay: RiseIn.stagger(i),
            child: DroneTile(
              drone: drone,
              modelName: _modelName(models, drone.droneModelId),
              onActions: drone.status.isInMission || !hubActive
                  ? null
                  : () => _openDroneActions(context, ref, drone),
            ),
          );
        },
      ),
      AsyncError(:final error) => MessageView(
        icon: Icons.cloud_off_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// El alta solo se ofrece con una central elegida y activa: Nest responde
/// `403 La central está suspendida.` en cualquier otro caso.
class _NewDroneButton extends ConsumerWidget {
  const _NewDroneButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    if (!(hub?.isActive ?? false)) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () => context.push('/fleet/new'),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nuevo dron'),
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
/// dos: "Registrar mantenimiento" usa POST .../maintenance; los cambios de
/// estado usan PATCH .../status.
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
  final input = await showMaintenanceSheet(
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
  final input = await showMaintenanceSheet(
    context,
    mandatory: true,
    initialReason: drone.maintenanceReason ?? '',
    initialDate: drone.maintenanceUntil ?? '',
  );
  if (input == null || !context.mounted) return;

  try {
    await ref
        .read(registerMaintenanceProvider.notifier)
        .register(
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
