import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { assertDispatchWindow } from '../orders/plan-dispatch.rules';
import { CEILING_TOO_LOW } from '../airspace/terrain.rules';
import { usablePayloadKg } from '../fleet/drone-types';
import { missionBatteryPercent } from '../simulation/flight-energy.rules';
import { isAwaitingHub } from './fallback.rules';

/** RF-11: peso de la carga en kg, con el peso por unidad del lote. */
export function payloadKgOf(
  lot: { unitWeightG?: number | null },
  quantity: number,
): number {
  return Math.round((lot.unitWeightG ?? 100) * quantity) / 1000;
}

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
  'Solo se autoriza un pedido recibido o reasignado a tu central.';

export const ONLY_PENDING_LOAD_IS_CONFIRMED =
  'Solo se confirma la carga de un pedido pendiente de carga.';

export const NOT_THE_LOADING_HUB =
  'Solo el despachador de la central de origen confirma la carga.';

export const MISSING_DESTINATION = 'El pedido no tiene coordenadas de destino.';

export const WEATHER_BLOCKS = 'El clima simulado no permite volar.';

export const DRONE_MAINTENANCE = 'El dron está en mantenimiento.';

export const DRONE_OUT_OF_SERVICE = 'El dron está fuera de servicio.';

export const DRONE_IN_MISSION = 'El dron ya está en misión.';

export const PAYLOAD_TOO_HEAVY = 'La carga supera la capacidad del dron.';

export const NEEDS_COLD_COMPARTMENT =
  'La carga exige frío y el dron no lleva el compartimento.';

export const BATTERY_TOO_LOW =
  'La batería no alcanza para la ida, el regreso, la subida y la reserva del 20 %.';

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
  /** RF-49: lleva el compartimento de frío (resta 1 kg de carga útil). */
  coldCompartment?: boolean;
  /** Crucero del tipo, en km/h: decide el tiempo de llegada. */
  cruiseKmh?: number;
  /** Energía de la batería del tipo, en Wh: decide el programado. */
  batteryWh?: number;
  /** RF-46: techo de servicio sobre el nivel del mar. */
  ceilingM?: number;
  /** RF-46: % de batería por metro de ascenso. */
  climbPercentPerM?: number;
  held: HeldMission | null;
  /** Batería ahora, con lo que recargó en tierra. */
  batteryPercent: number;
  /** Fin de su último vuelo; `null` si nunca ha volado. */
  lastFlightEndedAt: Date | null;
};

export type AuthorizableOrder = {
  status: OrderStatus;
  fallbackKind: FallbackKind | null;
  missionType: MissionType;
  destinationKind: DestinationKind;
  saleType: SaleType;
  scheduledFor: string | null;
  scheduledAt?: Date | null;
  windowEndsAt?: Date | null;
  reassignedFromHubId?: string | null;
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
  /** Minutos de crucero hasta el destino (urgencia). */
  etaMin: number;
  /** Wh que gasta la misión completa (programado). */
  energyWh: number;
};

/** El clima del corredor para un tipo de dron: su viento límite es el suyo. */
export type CandidateWeather = { flyable: boolean; reason: string | null };

/**
 * RF-46: el terreno de la misión para un tipo de dron: metros de ascenso de
 * ida y de regreso, y el punto más alto del vuelo.
 */
export type CandidateTerrain = { climbM: number; peakMslM: number };

/** RF-46: la batería de la misión más la de subir. */
export function missionWithClimbPercent(
  distanceKm: number,
  drone: Pick<DroneCandidate, 'maxRangeKm' | 'climbPercentPerM'>,
  terrain?: CandidateTerrain,
): number {
  return (
    missionBatteryPercent(distanceKm, drone.maxRangeKm) +
    (terrain?.climbM ?? 0) * (drone.climbPercentPerM ?? 0)
  );
}

export function assertCanAuthorize(
  order: AuthorizableOrder,
  today: string,
  prescriptionVerified?: boolean,
  now?: Date,
): void {
  if (!isAwaitingHub(order)) {
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
  if (now) {
    assertDispatchWindow(order, now);
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
  /** RF-11: peso real de la carga; sin él, 0,5 kg por unidad (filas de antes). */
  payloadKg?: number;
  /** El pedido exige frío: solo un dron con compartimento. */
  requiresCold?: boolean;
  weatherFlyable: boolean;
  /** Por qué no deja volar el clima (tormenta o viento); sin él, el genérico. */
  weatherReason?: string | null;
  /**
   * Km del corredor, o km equivalentes con el clima (RF-32): con viento en
   * contra el crucero cuesta como uno más largo. `weather`, si viene, es el
   * clima con el límite de viento de ese tipo y manda sobre el general.
   */
  candidates: Array<{
    drone: DroneCandidate;
    distanceKm: number | null;
    weather?: CandidateWeather;
    terrain?: CandidateTerrain;
  }>;
}): { chosen: ChosenDrone | null; discarded: DiscardedDrone[] } {
  const discarded: DiscardedDrone[] = [];
  const eligible: RankedCandidate[] = [];
  const payloadKg = input.payloadKg ?? input.quantity * LEGACY_UNIT_MASS_KG;
  for (const candidate of input.candidates) {
    const reason = discardReason(
      input.missionType,
      payloadKg,
      candidate.weather?.flyable ?? input.weatherFlyable,
      candidate.drone,
      candidate.distanceKm,
      candidate.weather?.reason ?? input.weatherReason,
      input.requiresCold ?? false,
      candidate.terrain,
    );
    if (reason) {
      discarded.push({
        droneId: candidate.drone.id,
        identifier: candidate.drone.identifier,
        reason,
      });
      continue;
    }
    eligible.push(
      ranked(candidate.drone, candidate.distanceKm ?? 0, candidate.terrain),
    );
  }
  const free = eligible.filter(
    (entry) => entry.drone.status === DroneStatus.AVAILABLE,
  );
  const pool = free.length ? free : eligible;
  pool.sort(input.missionType === MissionType.EMERGENCY ? byArrival : byEnergy);
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

/** Sin peso por unidad en el lote (filas de antes de RF-11): 0,5 kg. */
export const LEGACY_UNIT_MASS_KG = 0.5;

function ranked(
  drone: DroneCandidate,
  distanceKm: number,
  terrain?: CandidateTerrain,
): RankedCandidate {
  const etaMin = drone.cruiseKmh
    ? (distanceKm / drone.cruiseKmh) * 60
    : distanceKm;
  const energyWh = drone.batteryWh
    ? (missionWithClimbPercent(distanceKm, drone, terrain) / 100) *
      drone.batteryWh
    : distanceKm;
  return {
    drone,
    distanceKm,
    etaMin: Math.round(etaMin * 10) / 10,
    energyWh: Math.round(energyWh),
  };
}

/**
 * RF-11, `operacion/flota.md`: en una urgencia gana el que llega antes. Si
 * empatan (dos drones del mismo tipo), decide la rotación.
 */
function byArrival(left: RankedCandidate, right: RankedCandidate): number {
  return left.etaMin - right.etaMin || byRotation(left, right);
}

/** En un programado gana el que gasta menos energía; empate, la rotación. */
function byEnergy(left: RankedCandidate, right: RankedCandidate): number {
  return left.energyWh - right.energyWh || byRotation(left, right);
}

/**
 * Entre los drones que pueden cumplir, gana el que lleva más tiempo en
 * tierra (el que nunca ha volado, primero): así la flota se alterna y no
 * vuela siempre el mismo. Empatan: el de más batería y, al final, el
 * identificador, para que el resultado sea estable.
 */
function byRotation(left: RankedCandidate, right: RankedCandidate): number {
  if (left.distanceKm !== right.distanceKm) {
    return left.distanceKm - right.distanceKm;
  }
  const leftLanded = left.drone.lastFlightEndedAt?.getTime() ?? -Infinity;
  const rightLanded = right.drone.lastFlightEndedAt?.getTime() ?? -Infinity;
  if (leftLanded !== rightLanded) {
    return leftLanded - rightLanded;
  }
  if (left.drone.batteryPercent !== right.drone.batteryPercent) {
    return right.drone.batteryPercent - left.drone.batteryPercent;
  }
  return left.drone.identifier.localeCompare(right.drone.identifier);
}

export function discardReason(
  missionType: MissionType,
  payloadKg: number,
  weatherFlyable: boolean,
  candidate: DroneCandidate,
  distanceKm: number | null,
  weatherReason?: string | null,
  requiresCold = false,
  terrain?: CandidateTerrain,
): string | null {
  if (!weatherFlyable) {
    return weatherReason ?? WEATHER_BLOCKS;
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
  if (requiresCold && !candidate.coldCompartment) {
    return NEEDS_COLD_COMPARTMENT;
  }
  const usable = usablePayloadKg(
    candidate.maxPayloadKg,
    candidate.coldCompartment ?? false,
  );
  if (payloadKg > usable + 1e-9) {
    return PAYLOAD_TOO_HEAVY;
  }
  if (distanceKm == null) {
    return NO_CORRIDOR;
  }
  if (
    terrain &&
    candidate.ceilingM != null &&
    terrain.peakMslM > candidate.ceilingM
  ) {
    return CEILING_TOO_LOW;
  }
  if (
    missionWithClimbPercent(distanceKm, candidate, terrain) >
    candidate.batteryPercent
  ) {
    return BATTERY_TOO_LOW;
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
