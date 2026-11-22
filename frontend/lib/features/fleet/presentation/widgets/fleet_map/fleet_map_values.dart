import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import '../../../data/fleet_models.dart';
import '../../../../tracking/data/telemetry_models.dart';

/// Etiquetas tomadas de la flota y las centrales, sin datos del solicitante.
class FleetMapValues {
  const FleetMapValues({
    this.map,
    this.drones = const [],
    this.models = const [],
  });
  final FleetMap? map;
  final List<Drone> drones;
  final List<DroneModel> models;

  String titleOf(FleetFlight flight) {
    final drone = drones.where((d) => d.id == flight.droneId).firstOrNull;
    final model = models.where((m) => m.id == drone?.droneModelId).firstOrNull;
    return model == null
        ? flight.identifier
        : '${model.name} ${flight.identifier}';
  }

  String? routeOf(FleetFlight flight) {
    final origin = map?.hubs.where((h) => h.id == flight.hubId).firstOrNull;
    if (origin == null) return null;
    FleetMapHub? destination;
    if (flight.route.isNotEmpty && flight.route.last.length >= 2) {
      final end = flight.route.last;
      destination = map?.hubs
          .where(
            (h) =>
                h.id != origin.id &&
                (h.longitude - end[0]).abs() < 0.00001 &&
                (h.latitude - end[1]).abs() < 0.00001,
          )
          .firstOrNull;
    }
    if (destination != null) {
      return flight.returning
          ? '${destination.name} → ${origin.name}'
          : '${origin.name} → ${destination.name}';
    }
    return flight.returning
        ? 'Regreso a ${origin.name}'
        : 'Desde ${origin.name}';
  }
}

String fleetFlightPhase(FleetFlight f) => f.linkLost
    ? 'Sin enlace'
    : f.returning
    ? 'Regresando'
    : f.phase?.label ?? f.orderStatus.label;

String fleetFlightReadings(FleetFlight f) => [
  if (f.batteryPercent case final b?) 'Batería ${b.round()} %',
  if (!f.returning && f.etaSeconds != null && f.etaSeconds! >= 0)
    f.etaSeconds == 0
        ? 'Llegando'
        : 'Llegada en ${(f.etaSeconds! / 60).ceil()} min',
  if (f.requiresColdChain && f.temperatureC != null)
    '${f.temperatureC!.toStringAsFixed(1).replaceAll('.', ',')} °C',
].join(' · ');

String fleetFlightAlerts(FleetFlight f) => [
  if (f.batteryAlert) 'Batería baja',
  if (f.failureAlert) 'Falla reportada',
  if (f.coldChainAlert ||
      (f.requiresColdChain && isColdChainBreach(f.temperatureC)))
    'Frío fuera de rango',
  if (f.linkLost) 'Posición estimada',
].join(' · ');
