import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';

/** El inventario no guarda masa. Cada unidad cuenta 0,5 kg. */
export const UNIT_MASS_KG = 0.5;

export const PRESCRIPTION_NOT_VERIFIED =
  'Debes verificar la fórmula antes de autorizar.';

export const LOT_NOT_AVAILABLE =
  'No hay un lote vigente con la cantidad del pedido.';

export const SCHEDULED_TOO_EARLY =
  'Este pedido programado todavía no llega a su fecha.';

export const NO_ELIGIBLE_DRONE =
  'Ningún dron de la central puede cumplir esta salida.';

export const NOT_THE_AUTHORIZING_HUB =
  'Solo el despachador de la central que tiene el insumo autoriza este pedido.';

export const ONLY_RECEIVED_IS_AUTHORIZED =
  'Solo se autoriza un pedido que sigue en recibido.';

export const MISSING_DESTINATION = 'El pedido no tiene coordenadas de destino.';

export const WEATHER_BLOCKS = 'El clima simulado no permite volar.';

export const DRONE_MAINTENANCE = 'El dron está en mantenimiento.';

export const DRONE_OUT_OF_SERVICE = 'El dron está fuera de servicio.';

export const DRONE_IN_MISSION = 'El dron ya está en misión.';

export const PAYLOAD_TOO_HEAVY = 'La carga supera la capacidad del dron.';

export const RANGE_TOO_SHORT = 'La ida y vuelta superan el alcance del dron.';

export const NO_CORRIDOR = 'No hay un corredor libre de geovallas.';

export type HeldMission = {
  orderId: string;
  missionType: MissionType;
  status: OrderStatus;
};

export type DroneCandidate = {
  id: string;
  identifier: string;
  status: DroneStatus;
  maxPayloadKg: number;
  maxRangeKm: number;
  held: HeldMission | null;
};

export type AuthorizableOrder = {
  status: OrderStatus;
  missionType: MissionType;
  destinationKind: DestinationKind;
  saleType: SaleType;
  scheduledFor: string | null;
  latitude: number | null;
  longitude: number | null;
  originHubId: string | null;
};

export type ChosenDrone = {
  droneId: string;
  identifier: string;
  distanceKm: number;
  preemptsOrderId: string | null;
};

export type DiscardedDrone = {
  droneId: string;
  identifier: string;
  reason: string;
};

type RankedCandidate = {
  drone: DroneCandidate;
  distanceKm: number;
};

/** En este MVP el clima simulado deja volar. Los tests pueden inyectar un bloqueo. */
export function simulatedWeather(): { flyable: boolean } {
  return { flyable: true };
}

export function assertCanAuthorize(
  order: AuthorizableOrder,
  today: string,
  prescriptionVerified?: boolean,
): void {
  if (order.status !== OrderStatus.RECEIVED) {
    throw new BadRequestException(ONLY_RECEIVED_IS_AUTHORIZED);
  }
  if (
    order.destinationKind === DestinationKind.PERSON &&
    order.saleType === SaleType.PRESCRIPTION &&
    prescriptionVerified !== true
  ) {
    throw new BadRequestException(PRESCRIPTION_NOT_VERIFIED);
  }
  if (
    order.missionType === MissionType.SCHEDULED &&
    order.scheduledFor != null &&
    order.scheduledFor > today
  ) {
    throw new BadRequestException(SCHEDULED_TOO_EARLY);
  }
  if (order.latitude == null || order.longitude == null) {
    throw new BadRequestException(MISSING_DESTINATION);
  }
}

export function assertAuthorizingHub(
  originHubId: string | null,
  dispatcherHubId: string,
): void {
  if (originHubId != null && originHubId !== dispatcherHubId) {
    throw new ForbiddenException(NOT_THE_AUTHORIZING_HUB);
  }
}

export function chooseDrone(input: {
  missionType: MissionType;
  quantity: number;
  weatherFlyable: boolean;
  candidates: Array<{ drone: DroneCandidate; distanceKm: number | null }>;
}): { chosen: ChosenDrone | null; discarded: DiscardedDrone[] } {
  const discarded: DiscardedDrone[] = [];
  const eligible: RankedCandidate[] = [];
  for (const candidate of input.candidates) {
    const reason = discardReason(
      input.missionType,
      input.quantity,
      input.weatherFlyable,
      candidate.drone,
      candidate.distanceKm,
    );
    if (reason) {
      discarded.push({
        droneId: candidate.drone.id,
        identifier: candidate.drone.identifier,
        reason,
      });
      continue;
    }
    eligible.push({
      drone: candidate.drone,
      distanceKm: candidate.distanceKm ?? 0,
    });
  }
  const free = eligible.filter(
    (entry) => entry.drone.status === DroneStatus.AVAILABLE,
  );
  const pool = free.length ? free : eligible;
  pool.sort((left, right) => {
    if (left.distanceKm !== right.distanceKm) {
      return left.distanceKm - right.distanceKm;
    }
    return left.drone.identifier.localeCompare(right.drone.identifier);
  });
  const winner = pool[0];
  if (!winner) {
    return { chosen: null, discarded };
  }
  return {
    chosen: {
      droneId: winner.drone.id,
      identifier: winner.drone.identifier,
      distanceKm: winner.distanceKm,
      preemptsOrderId:
        winner.drone.status === DroneStatus.IN_MISSION
          ? (winner.drone.held?.orderId ?? null)
          : null,
    },
    discarded,
  };
}

export function discardReason(
  missionType: MissionType,
  quantity: number,
  weatherFlyable: boolean,
  candidate: DroneCandidate,
  distanceKm: number | null,
): string | null {
  if (!weatherFlyable) {
    return WEATHER_BLOCKS;
  }
  if (candidate.status === DroneStatus.MAINTENANCE) {
    return DRONE_MAINTENANCE;
  }
  if (candidate.status === DroneStatus.OUT_OF_SERVICE) {
    return DRONE_OUT_OF_SERVICE;
  }
  if (!canTake(missionType, candidate)) {
    return DRONE_IN_MISSION;
  }
  if (quantity * UNIT_MASS_KG > candidate.maxPayloadKg) {
    return PAYLOAD_TOO_HEAVY;
  }
  if (distanceKm == null) {
    return NO_CORRIDOR;
  }
  if (distanceKm * 2 > candidate.maxRangeKm) {
    return RANGE_TOO_SHORT;
  }
  return null;
}

function canTake(missionType: MissionType, candidate: DroneCandidate): boolean {
  if (candidate.status === DroneStatus.AVAILABLE) {
    return true;
  }
  return (
    candidate.status === DroneStatus.IN_MISSION &&
    missionType === MissionType.EMERGENCY &&
    candidate.held?.missionType === MissionType.SCHEDULED &&
    candidate.held.status === OrderStatus.PENDING_LOAD
  );
}
