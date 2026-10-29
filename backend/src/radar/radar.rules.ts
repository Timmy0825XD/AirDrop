import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { LiveFlight } from '../simulation/simulation.rules';

/** Pedidos que una central todavía tiene en marcha (conteo del panel). */
export const RADAR_QUEUE_STATUSES = [
  OrderStatus.RECEIVED,
  OrderStatus.ASSIGNED,
  OrderStatus.PENDING_LOAD,
  OrderStatus.IN_FLIGHT,
  OrderStatus.AWAITING_DELIVERY,
  OrderStatus.RETURNING,
];

export type FleetCounts = {
  available: number;
  inMission: number;
  maintenance: number;
  outOfService: number;
  total: number;
};

export function countFleet(
  drones: Array<{ status: DroneStatus }>,
): FleetCounts {
  const counts: FleetCounts = {
    available: 0,
    inMission: 0,
    maintenance: 0,
    outOfService: 0,
    total: drones.length,
  };
  for (const drone of drones) {
    if (drone.status === DroneStatus.AVAILABLE) counts.available += 1;
    else if (drone.status === DroneStatus.IN_MISSION) counts.inMission += 1;
    else if (drone.status === DroneStatus.MAINTENANCE) counts.maintenance += 1;
    else counts.outOfService += 1;
  }
  return counts;
}

type FlightOrder = {
  id: string;
  missionType: MissionType;
  destinationKind: DestinationKind;
  destinationHubId: string | null;
  status: OrderStatus;
  quantity: number;
  requiresColdChain: boolean;
  medicationName: string;
  coldChainAlertAt: Date | null;
};

type FlightDrone = { id: string; identifier: string; hubId: string };

/**
 * Un vuelo para el radar. El medicamento solo se dice cuando el destino es
 * una central: si va a una persona, el radar no revela qué recibe.
 */
export function presentRadarFlight(
  drone: FlightDrone,
  order: FlightOrder,
  flight: LiveFlight | null,
  alerts: { battery: boolean; failure: boolean },
) {
  return {
    orderId: order.id,
    droneId: drone.id,
    identifier: drone.identifier,
    hubId: drone.hubId,
    destinationKind: order.destinationKind,
    destinationHubId: order.destinationHubId,
    missionType: order.missionType,
    orderStatus: order.status,
    quantity: order.quantity,
    requiresColdChain: order.requiresColdChain,
    medicationName:
      order.destinationKind === DestinationKind.HUB
        ? order.medicationName
        : null,
    phase: flight?.phase ?? null,
    leg: flight?.leg ?? null,
    latitude: flight?.latitude ?? null,
    longitude: flight?.longitude ?? null,
    altitudeM: flight?.altitudeM ?? null,
    speedKmh: flight?.speedKmh ?? null,
    batteryPercent: flight?.batteryPercent ?? null,
    temperatureC: flight?.temperatureC ?? null,
    etaSeconds: flight?.etaSeconds ?? null,
    alerts: {
      battery: alerts.battery,
      failure: alerts.failure,
      coldChain: order.coldChainAlertAt != null,
    },
  };
}
