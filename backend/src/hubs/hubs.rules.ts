import { BadRequestException } from '@nestjs/common';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';

export const EMPTY_HUB_UPDATE =
  'Debes enviar al menos un campo para actualizar.';

export const COORDINATES_TOGETHER =
  'La latitud y la longitud se cambian juntas.';

export const HUB_HAS_LIVE_ORDERS =
  'No se puede mover una central con vuelos o pedidos en curso.';

export const HUB_INSIDE_GEOFENCE =
  'La nueva ubicación queda dentro de una geovalla.';

/** Pedidos que dependen de la ubicación actual de la central. */
export const LIVE_ORDER_STATUSES = [
  OrderStatus.ASSIGNED,
  OrderStatus.PENDING_LOAD,
  OrderStatus.IN_FLIGHT,
  OrderStatus.AWAITING_DELIVERY,
  OrderStatus.RETURNING,
];

/** Un pedido reasignado a la central se pensó desde su ubicación actual. */
export const REASSIGNED_HERE = {
  status: OrderStatus.REASSIGNED,
  fallbackKind: FallbackKind.HUB,
};

type HubPatch = {
  name?: string;
  type?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  contactPhone?: string;
  contactEmail?: string;
};

export function assertHubPatch(dto: HubPatch): void {
  if (Object.values(dto).every((value) => value === undefined)) {
    throw new BadRequestException(EMPTY_HUB_UPDATE);
  }
  if ((dto.latitude === undefined) !== (dto.longitude === undefined)) {
    throw new BadRequestException(COORDINATES_TOGETHER);
  }
}

/** Solo cuenta como mover la central si cambia algún número de la ubicación. */
export function movesLocation(
  current: { latitude: number; longitude: number },
  dto: HubPatch,
): boolean {
  return (
    dto.latitude !== undefined &&
    dto.longitude !== undefined &&
    (dto.latitude !== current.latitude || dto.longitude !== current.longitude)
  );
}
