import '../../../../fleet/data/fleet_flight.dart';
import '../../../../tracking/data/telemetry_models.dart';

String operatorFlightAlerts(FleetFlight flight) => [
  if (flight.batteryAlert) 'Batería baja',
  if (flight.failureAlert) 'Falla reportada',
  if (flight.coldChainAlert ||
      (flight.requiresColdChain && isColdChainBreach(flight.temperatureC)))
    'Cadena de frío fuera de rango',
  if (flight.linkLost) 'Sin enlace: posición estimada',
].join(' · ');

String operatorFlightPhase(FleetFlight flight) => flight.linkLost
    ? 'Sin enlace'
    : flight.returning
    ? 'Regresando'
    : flight.phase?.label ?? flight.orderStatus.label;

String operatorFlightReadings(FleetFlight flight) => [
  if (flight.requiresColdChain && flight.temperatureC != null)
    '${flight.temperatureC!.toStringAsFixed(1).replaceAll('.', ',')} °C',
  if (!flight.returning && flight.etaSeconds != null)
    'Llegada en ${(flight.etaSeconds! / 60).ceil()} min',
].join(' · ');
