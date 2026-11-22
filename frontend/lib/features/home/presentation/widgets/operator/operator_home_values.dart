import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';
import '../../../../fleet/data/fleet_flight.dart';
import '../../../../fleet/data/fleet_models.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../../tracking/data/telemetry_models.dart';

/// Datos de presentación: no decide estados del dron ni protocolos de vuelo.
class OperatorHomeValues {
  const OperatorHomeValues({
    this.hubs = const AsyncLoading(),
    this.drones = const AsyncLoading(),
    this.flights = const AsyncLoading(),
    this.dashboard = const AsyncLoading(),
    this.models = const [],
  });

  final AsyncValue<List<Hub>> hubs;
  final AsyncValue<List<Drone>> drones;
  final AsyncValue<List<FleetFlight>> flights;
  final AsyncValue<FleetDashboard> dashboard;
  final List<DroneModel> models;

  String get scope => switch (hubs.value) {
    null =>
      hubs.hasError ? 'Centrales sin actualizar' : 'Cargando tus centrales…',
    [] => 'Sin centrales asignadas',
    [final hub] => hub.name,
    final rows => '${rows.length} centrales',
  };

  int? count(DroneStatus status) =>
      drones.value?.where((drone) => drone.status == status).length;

  bool get loading => !drones.hasValue || !flights.hasValue;
  bool get hubsFailed => hubs.hasError;
  bool get flightsLoading => !flights.hasValue && !flights.hasError;
  bool get flightsFailed => flights.hasError;
  bool get allClear =>
      !loading && error == null && reviews.isEmpty && alerts.isEmpty;

  String? get error {
    final errors = {
      for (final state in [hubs, drones, flights])
        if (state.hasError) ApiException.messageOf(state.error!),
    };
    return errors.isEmpty ? null : errors.join('\n');
  }

  String hubName(String id) {
    for (final hub in hubs.value ?? <Hub>[]) {
      if (hub.id == id) return hub.name;
    }
    return 'Central asignada';
  }

  String droneTitle(String identifier, String droneId) {
    final drone = (drones.value ?? <Drone>[])
        .where((d) => d.id == droneId)
        .firstOrNull;
    final model = models.where((m) => m.id == drone?.droneModelId).firstOrNull;
    return model == null ? identifier : '${model.name} $identifier';
  }

  List<Drone> get reviews {
    final rows = (drones.value ?? <Drone>[])
        .where(
          (d) =>
              d.status.isOutOfFleet ||
              d.status == DroneStatus.unknown ||
              (d.status == DroneStatus.available &&
                  (d.maintenanceDue || d.maintenanceOverdue)),
        )
        .toList();
    rows.sort((a, b) {
      final priority = _reviewPriority(a).compareTo(_reviewPriority(b));
      return priority == 0 ? a.identifier.compareTo(b.identifier) : priority;
    });
    return rows;
  }

  List<FleetFlight> get alerts => (flights.value ?? <FleetFlight>[])
      .where(operatorFlightNeedsReview)
      .toList();
}

bool operatorFlightNeedsReview(FleetFlight f) =>
    f.hasAlert ||
    f.linkLost ||
    (f.requiresColdChain && isColdChainBreach(f.temperatureC));

int _reviewPriority(Drone drone) => switch (drone) {
  Drone(status: DroneStatus.grounded) => 0,
  Drone(maintenanceOverdue: true) => 1,
  Drone(maintenanceDue: true) => 2,
  Drone(status: DroneStatus.maintenance) => 3,
  _ => 4,
};
