import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { FallbackOption } from '../orders/order.entity';
import { todayInColombia } from '../orders/orders.rules';
import { LngLat, haversineKm } from '../routing/routing.rules';

/** Un programado sin dron libre se vuelve a intentar cada 15 minutos. */
export const DEFAULT_SCHEDULED_RETRY_MS = 15 * 60 * 1000;

/** El traslado convencional sugiere hasta tres centrales con el insumo. */
export const MAX_FALLBACK_OPTIONS = 3;

export const CONVENTIONAL_WITH_STOCK =
  'Ningún dron de la red puede cumplir esta salida. Toca un traslado convencional desde una central con el insumo.';

export const CONVENTIONAL_WITHOUT_STOCK =
  'Ningún dron de la red puede cumplir esta salida y ninguna otra central tiene el insumo.';

export function reassignedReason(hubName: string): string {
  return `Ningún dron de la central podía salir. El pedido pasó a ${hubName}.`;
}

export function retryReason(retryMs: number): string {
  const minutes = Math.max(1, Math.round(retryMs / 60000));
  return `Ningún dron está libre. Se reintenta solo cada ${minutes} min durante el día.`;
}

/**
 * `SCHEDULED_RETRY_MS` permite acortar el reintento en pruebas; sin variable
 * (o con un valor no válido) son 15 minutos.
 */
export function scheduledRetryMs(): number {
  const configured = Number(process.env.SCHEDULED_RETRY_MS);
  return Number.isInteger(configured) && configured > 0
    ? configured
    : DEFAULT_SCHEDULED_RETRY_MS;
}

export type FallbackOrder = {
  status: OrderStatus;
  missionType: MissionType;
  originHubId: string | null;
  destinationHubId: string | null;
  fallbackKind: FallbackKind | null;
  fallbackReason: string | null;
  fallbackOptions: FallbackOption[] | null;
  reassignedFromHubId: string | null;
  reassignedAt: Date | null;
  retryAfter: Date | null;
  prescriptionVerifiedAt: Date | null;
};

type HubPlace = LngLat & { id: string; name: string };

/** Un pedido se reasigna una sola vez; después solo queda el convencional. */
export function canReassign(order: {
  reassignedFromHubId: string | null;
}): boolean {
  return order.reassignedFromHubId == null;
}

/** Un pedido reasignado a otra central entra a su cola como uno recibido. */
export function isAwaitingHub(order: {
  status: OrderStatus;
  fallbackKind: FallbackKind | null;
}): boolean {
  return (
    order.status === OrderStatus.RECEIVED ||
    (order.status === OrderStatus.REASSIGNED &&
      order.fallbackKind === FallbackKind.HUB)
  );
}

/**
 * Solo un programado espera un dron, y solo mientras el siguiente intento
 * caiga el mismo día. Una urgencia no espera, y un pedido ya reasignado
 * tampoco: pasa al convencional.
 */
export function shouldRetry(
  order: FallbackOrder,
  now: Date,
  nextRetryAt: Date,
): boolean {
  return (
    order.missionType === MissionType.SCHEDULED &&
    canReassign(order) &&
    todayInColombia(nextRetryAt) === todayInColombia(now)
  );
}

/** Centrales que no se prueban con dron: la que falló, la de destino y la anterior. */
export function droneSearchExclusions(
  order: Pick<FallbackOrder, 'destinationHubId' | 'reassignedFromHubId'>,
  failingHubId: string,
): Set<string> {
  const ids = [failingHubId, order.destinationHubId, order.reassignedFromHubId];
  return new Set(ids.filter((id): id is string => id != null));
}

/** De la más cercana al destino a la más lejana; empate por nombre. */
export function rankHubsByDistance<T extends HubPlace>(
  hubs: T[],
  destination: LngLat,
): Array<{ hub: T; distanceKm: number }> {
  return hubs
    .map((hub) => ({
      hub,
      distanceKm: Math.round(haversineKm(hub, destination) * 100) / 100,
    }))
    .sort((left, right) => {
      if (left.distanceKm !== right.distanceKm) {
        return left.distanceKm - right.distanceKm;
      }
      return left.hub.name.localeCompare(right.hub.name);
    });
}

export function applyRetry(
  order: FallbackOrder,
  hubId: string,
  nextRetryAt: Date,
  retryMs: number,
): void {
  order.status = OrderStatus.RECEIVED;
  order.originHubId = hubId;
  order.fallbackKind = FallbackKind.RETRY;
  order.fallbackReason = retryReason(retryMs);
  order.fallbackOptions = null;
  order.retryAfter = nextRetryAt;
}

/**
 * El pedido cambia de central de origen y espera a que su despachador lo
 * autorice. La fórmula la vuelve a verificar esa central.
 */
export function applyHubReassignment(
  order: FallbackOrder,
  fromHubId: string,
  target: FallbackOption,
  now: Date,
): void {
  order.status = OrderStatus.REASSIGNED;
  order.originHubId = target.hubId;
  order.reassignedFromHubId = fromHubId;
  order.reassignedAt = now;
  order.fallbackKind = FallbackKind.HUB;
  order.fallbackReason = reassignedReason(target.name);
  order.fallbackOptions = [target];
  order.retryAfter = null;
  order.prescriptionVerifiedAt = null;
}

/** Estado final: ningún dron despega y quien pidió ve dónde está el insumo. */
export function applyConventional(
  order: FallbackOrder,
  fromHubId: string,
  withStock: FallbackOption[],
  now: Date,
): void {
  const options = withStock.slice(0, MAX_FALLBACK_OPTIONS);
  order.status = OrderStatus.REASSIGNED;
  order.originHubId = fromHubId;
  order.reassignedFromHubId = order.reassignedFromHubId ?? fromHubId;
  order.reassignedAt = now;
  order.fallbackKind = FallbackKind.CONVENTIONAL;
  order.fallbackReason = options.length
    ? CONVENTIONAL_WITH_STOCK
    : CONVENTIONAL_WITHOUT_STOCK;
  order.fallbackOptions = options;
  order.retryAfter = null;
}

/** Al conseguir dron, la alternativa deja de aplicar; la reasignación queda. */
export function clearFallback(order: FallbackOrder): void {
  order.fallbackKind = null;
  order.fallbackReason = null;
  order.fallbackOptions = null;
  order.retryAfter = null;
}
