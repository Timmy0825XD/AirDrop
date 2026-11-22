import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../data/fleet_models.dart';
import '../data/fleet_providers.dart';
import 'widgets/drone_status_sheet.dart';
import 'widgets/maintenance_sheet.dart';
import 'widgets/fleet_list_page.dart';
import 'widgets/fleet_list_values.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});
  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> {
  final _search = TextEditingController();
  FleetFilter _filter = FleetFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _selectHub(String id) {
    _search.clear();
    setState(() => _filter = FleetFilter.all);
    ref.read(fleetHubProvider.notifier).select(id);
  }

  @override
  Widget build(BuildContext context) {
    final data = FleetListValues(
      hubs: ref.watch(assignedHubsProvider),
      hub: ref.watch(effectiveHubProvider),
      drones: ref.watch(dronesProvider),
      models: ref.watch(fleetModelsProvider),
      query: _search.text,
      filter: _filter,
    );
    return AutoRefresh(
      onTick: () => _refreshFleet(ref),
      child: FleetListPage(
        data: data,
        search: _search,
        onQuery: (_) => setState(() {}),
        onFilter: (value) => setState(() => _filter = value),
        onHub: _selectHub,
        onRefresh: () => _refreshFleet(ref),
        onOpen: (path) => context.push(path),
        onManage: (drone) => _openDroneActions(context, ref, drone),
        onClear: () => setState(() {
          _search.clear();
          _filter = FleetFilter.all;
        }),
      ),
    );
  }
}

Future<void> _refreshFleet(WidgetRef ref) {
  ref.invalidate(assignedHubsProvider);
  ref.invalidate(dronesProvider);
  if (ref.read(fleetModelsProvider).hasError) {
    ref.invalidate(fleetModelsProvider);
  }
  return ref
      .read(dronesProvider.future)
      .then<void>((_) {}, onError: (Object _, StackTrace _) {});
}

/// Hoja de acciones. Cada botón dispara un endpoint distinto, nunca los
/// dos: "Enviar a mantenimiento" usa POST .../maintenance; disponible y
/// fuera de servicio usan PATCH .../status.
void _openDroneActions(BuildContext context, WidgetRef ref, Drone drone) {
  showDroneStatusSheet(
    context,
    drone: drone,
    actions: (
      toggleColdCompartment: () => _setColdCompartment(context, ref, drone),
      setAvailable: () => _patchStatus(
        context,
        ref,
        drone.id,
        const UpdateDroneStatusRequest(status: DroneStatus.available),
        'Dron disponible.',
      ),
      sendToMaintenance: () => _sendToMaintenance(context, ref, drone),
      putOutOfService: () => _putOutOfService(context, ref, drone),
      viewHistory: () => context.push(
        '/fleet/${drone.id}/maintenance?name=${drone.identifier}',
      ),
    ),
  );
}

/// RF-49: pone o quita el compartimento de frío. En misión Nest responde
/// 409 y el mensaje se muestra tal cual.
Future<void> _setColdCompartment(
  BuildContext context,
  WidgetRef ref,
  Drone drone,
) async {
  final install = !drone.coldCompartment;
  try {
    await ref
        .read(fleetRepositoryProvider)
        .setColdCompartment(drone.id, installed: install);
    ref.invalidate(dronesProvider);
    ref.invalidate(operatorDronesProvider);
    if (!context.mounted) return;
    showAppSnack(
      context,
      install
          ? 'Compartimento de frío instalado.'
          : 'Compartimento de frío retirado.',
    );
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  }
}

/// `PATCH .../status` con `out_of_service`: indefinido, solo el motivo
/// (Nest no guarda fecha).
Future<void> _putOutOfService(
  BuildContext context,
  WidgetRef ref,
  Drone drone,
) async {
  final input = await showMaintenanceSheet(context, withDate: false);
  if (input == null || !context.mounted) return;

  await _patchStatus(
    context,
    ref,
    drone.id,
    UpdateDroneStatusRequest(
      status: DroneStatus.outOfService,
      reason: input.reason,
    ),
    'Dron fuera de servicio.',
  );
}

/// `POST .../maintenance`: motivo y fecha obligatorios y el dron queda en
/// mantenimiento (temporal).
Future<void> _sendToMaintenance(
  BuildContext context,
  WidgetRef ref,
  Drone drone,
) async {
  final input = await showMaintenanceSheet(context, withDate: true);
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
    if (context.mounted) showAppSnack(context, 'Dron en mantenimiento.');
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  }
}

/// Un solo `PATCH` para las vías de disponible y de fuera de servicio. Los
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
    if (context.mounted) showErrorSnack(context, error.message);
  }
}
