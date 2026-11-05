import { DestinationKind } from '../common/enums/destination-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PlannedCorridor } from '../routing/routing.rules';
import { LiveFlight } from '../simulation/simulation.rules';

/** Estados en que un pedido todavía ocupa su dron. */
export const DRONE_HOLDING_STATUSES = [
  OrderStatus.PENDING_LOAD,
  OrderStatus.IN_FLIGHT,
  OrderStatus.AWAITING_DELIVERY,
  OrderStatus.RETURNING,
  OrderStatus.DELIVERED,
];

/**
 * Los mismos, sin `delivered`: un pedido vivo. Un entregado conserva su
 * `droneId` para siempre, así que no prueba que el dron siga ocupado.
 */
export const DRONE_LIVE_STATUSES = DRONE_HOLDING_STATUSES.filter(
  (status) => status !== OrderStatus.DELIVERED,
);

type HoldingOrder = {
  id: string;
  droneId: string | null;
  status: OrderStatus;
  updatedAt: Date;
};

/**
 * El pedido que ocupa cada dron en misión. Un pedido entregado conserva su
 * `droneId` para siempre, así que solo cuenta si el dron no tiene otro
 * pedido vivo (es el regreso vacío tras entregar). Entre iguales gana el más
 * reciente.
 */
export function activeOrderByDrone<T extends HoldingOrder>(
  orders: T[],
  droneIdsInMission: string[],
): Map<string, T> {
  const inMission = new Set(droneIdsInMission);
  const result = new Map<string, T>();
  for (const order of orders) {
    if (!order.droneId || !inMission.has(order.droneId)) {
      continue;
    }
    const current = result.get(order.droneId);
    if (!current || outranks(order, current)) {
      result.set(order.droneId, order);
    }
  }
  return result;
}

function outranks(candidate: HoldingOrder, current: HoldingOrder): boolean {
  const candidateLive = candidate.status !== OrderStatus.DELIVERED;
  const currentLive = current.status !== OrderStatus.DELIVERED;
  if (candidateLive !== currentLive) {
    return candidateLive;
  }
  return candidate.updatedAt.getTime() > current.updatedAt.getTime();
}

type FlightDrone = { id: string; identifier: string; hubId: string };

/** Solo lo del pedido que el operador necesita para volar. */
type FlightOrder = {
  id: string;
  status: OrderStatus;
  missionType: MissionType;
  destinationKind: DestinationKind;
  destinationHubId: string | null;
  requiresColdChain: boolean;
  coldChainAlertAt: Date | null;
  latitude: number | null;
  longitude: number | null;
};

type FlightRoutes = {
  route: PlannedCorridor | null;
  returnRoute: PlannedCorridor | null;
};

/**
 * RU-18 y CU-19: un vuelo como lo ve el operador. Trae el paquete completo de
 * la aeronave, la ruta y el punto de llegada, pero nada de quién recibe ni
 * qué lleva: ni solicitante, ni dirección, ni medicamento, ni fórmula. Solo
 * el peso de la carga y si va en frío.
 */
export function presentOperatorFlight(
  drone: FlightDrone,
  order: FlightOrder,
  flight: LiveFlight | null,
  alerts: { battery: boolean; failure: boolean },
  routes: FlightRoutes,
) {
  return {
    droneId: drone.id,
    identifier: drone.identifier,
    hubId: drone.hubId,
    orderId: order.id,
    orderStatus: order.status,
    missionType: order.missionType,
    requiresColdChain: order.requiresColdChain,
    phase: flight?.phase ?? null,
    leg: flight?.leg ?? null,
    latitude: flight?.latitude ?? null,
    longitude: flight?.longitude ?? null,
    altitudeM: flight?.altitudeM ?? null,
    speedKmh: flight?.speedKmh ?? null,
    batteryPercent: flight?.batteryPercent ?? null,
    payloadKg: flight?.payloadKg ?? null,
    temperatureC: flight?.temperatureC ?? null,
    latencyMs: flight?.latencyMs ?? null,
    etaSeconds: flight?.etaSeconds ?? null,
    alerts: {
      battery: alerts.battery,
      failure: alerts.failure,
      coldChain: order.coldChainAlertAt != null,
    },
    route: routes.route,
    returnRoute: routes.returnRoute,
    destination: destinationOf(order, routes.route),
  };
}

/**
 * El punto donde aterriza en destino: el final del corredor de ida (es lo que
 * vuela el dron); si todavía no hay corredor, el punto del pedido.
 */
function destinationOf(order: FlightOrder, route: PlannedCorridor | null) {
  const end = route?.coordinates[route.coordinates.length - 1];
  const longitude = end?.[0] ?? order.longitude;
  const latitude = end?.[1] ?? order.latitude;
  if (latitude == null || longitude == null) {
    return null;
  }
  return {
    kind: order.destinationKind,
    hubId:
      order.destinationKind === DestinationKind.HUB
        ? order.destinationHubId
        : null,
    latitude,
    longitude,
  };
}
