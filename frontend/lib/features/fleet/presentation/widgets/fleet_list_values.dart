import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_exception.dart';
import '../../../../core/widgets/search_picker_sheet.dart';
import '../../../hubs/data/hub_models.dart';
import '../../data/fleet_models.dart';

enum FleetFilter {
  all('Todos'),
  available('Disponibles'),
  inMission('En misión'),
  maintenance('En taller');

  const FleetFilter(this.label);
  final String label;
}

class FleetListValues {
  const FleetListValues({
    required this.hubs,
    required this.hub,
    required this.drones,
    required this.models,
    this.query = '',
    this.filter = FleetFilter.all,
  });
  final AsyncValue<List<Hub>> hubs;
  final Hub? hub;
  final AsyncValue<List<Drone>> drones;
  final AsyncValue<List<DroneModel>> models;
  final String query;
  final FleetFilter filter;
  bool get canManage => hub?.isActive == true;
  bool get loadingHubs => !hubs.hasValue && !hubs.hasError;
  bool get loadingDrones =>
      !drones.hasError &&
      (!drones.hasValue || drones.isReloading || rows == null);
  // Una recarga conserva datos solo si pertenecen a la central seleccionada.
  List<Drone>? get rows {
    final known = drones.value;
    return known == null || known.any((drone) => drone.hubId != hub?.id)
        ? null
        : known;
  }

  String? get error {
    final messages = {
      for (final state in [hubs, drones, models])
        if (state.hasError) ApiException.messageOf(state.error!),
    };
    return messages.isEmpty ? null : messages.join('\n');
  }

  String? modelName(String id) =>
      models.value?.where((m) => m.id == id).firstOrNull?.name;
  String flightPath(Drone drone) => drone.activeOrderId == null
      ? '/fleet/flights'
      : '/tracking/${drone.activeOrderId}';
  List<Drone> get shown => (rows ?? <Drone>[]).where((drone) {
    final matches = switch (filter) {
      FleetFilter.all => true,
      FleetFilter.available => drone.status == DroneStatus.available,
      FleetFilter.inMission => drone.status == DroneStatus.inMission,
      FleetFilter.maintenance => drone.status == DroneStatus.maintenance,
    };
    return matches &&
        PickerOption(
          value: drone,
          title: drone.identifier,
          subtitle: modelName(drone.droneModelId),
        ).matches(query);
  }).toList();
}
