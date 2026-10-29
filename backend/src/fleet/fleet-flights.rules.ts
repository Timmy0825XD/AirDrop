import { OrderStatus } from '../common/enums/order-status.enum';

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
