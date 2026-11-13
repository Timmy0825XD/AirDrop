import '../../tracking/data/telemetry_models.dart' show FlightAlert;
import 'fleet_flight.dart';
import 'fleet_map_models.dart';

/// Lo que llega por la sala de una central (`subscribe-hub`, §16 y §17)
/// mientras el operador mira el mapa.
sealed class FleetEvent {
  const FleetEvent();
}

/// `hub-telemetry`: un tick de un vuelo de la central.
class FleetTickReceived extends FleetEvent {
  const FleetTickReceived(this.tick);
  final FleetTick tick;
}

/// `hub-flight-status` o `hub-flight-ended`: un vuelo cambió de estado o
/// aterrizó de vuelta. El mapa vuelve a pedir `/fleet/map`.
class FleetFlightsChanged extends FleetEvent {
  const FleetFlightsChanged();
}

/// `hub-incident`: un dron tuvo un incidente en vuelo (RF-34).
class FleetIncidentReceived extends FleetEvent {
  const FleetIncidentReceived(this.incident);
  final FleetIncident incident;
}

/// `hub-reroute`: un vuelo cambió de ruta o se quedó sin camino (RF-33).
class FleetRerouteReceived extends FleetEvent {
  const FleetRerouteReceived(this.reroute);
  final FleetReroute reroute;
}

/// `alert`: batería, falla, frío o viento.
class FleetAlertReceived extends FleetEvent {
  const FleetAlertReceived(this.alert);
  final FlightAlert alert;
}
