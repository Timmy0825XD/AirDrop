import { UserRole } from '../common/enums/user-role.enum';
import { LiveFlight } from '../simulation/simulation.rules';

export const TELEMETRY_UNAVAILABLE =
  'La telemetría no está disponible. No se puede iniciar el vuelo.';

export type TelemetryView = 'map' | 'full';

export type TelemetryAccess = {
  view: TelemetryView;
  alerts: boolean;
};

export function telemetryAccess(
  user: { id: string; role: UserRole; hubIds: string[] },
  order: {
    requesterId: string | null;
    originHubId: string | null;
    destinationHubId: string | null;
  },
): TelemetryAccess | null {
  if (user.role === UserRole.REQUESTER) {
    if (order.requesterId !== user.id) {
      return null;
    }
    return { view: 'map', alerts: false };
  }
  // La central que recibe el traslado sigue el vuelo como el solicitante:
  // solo el mapa, sin los datos de la aeronave.
  if (
    user.role === UserRole.DISPATCHER &&
    order.destinationHubId &&
    order.destinationHubId !== order.originHubId &&
    user.hubIds.includes(order.destinationHubId)
  ) {
    return { view: 'map', alerts: false };
  }
  if (!order.originHubId || !user.hubIds.includes(order.originHubId)) {
    return null;
  }
  if (user.role === UserRole.DISPATCHER) {
    return { view: 'full', alerts: false };
  }
  if (user.role === UserRole.FLEET_OPERATOR) {
    return { view: 'full', alerts: true };
  }
  return null;
}

/** Despachador u operador siguen la sala de una central que tienen asignada. */
export function canFollowHub(
  user: { role: UserRole; hubIds: string[] },
  hubId: string,
): boolean {
  return (
    (user.role === UserRole.DISPATCHER ||
      user.role === UserRole.FLEET_OPERATOR) &&
    user.hubIds.includes(hubId)
  );
}

export function presentTelemetry(flight: LiveFlight, view: TelemetryView) {
  const map = {
    orderId: flight.orderId,
    droneId: flight.droneId,
    identifier: flight.identifier,
    latitude: flight.latitude,
    longitude: flight.longitude,
    altitudeM: flight.altitudeM,
    speedKmh: flight.speedKmh,
    phase: flight.phase,
    leg: flight.leg,
    status: flight.status,
    etaSeconds: flight.etaSeconds,
  };
  if (view === 'map') {
    return map;
  }
  return {
    ...map,
    batteryPercent: flight.batteryPercent,
    payloadKg: flight.payloadKg,
    temperatureC: flight.temperatureC,
    latencyMs: flight.latencyMs,
  };
}
