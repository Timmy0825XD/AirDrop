import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { UNIT_MASS_KG } from '../decision/decision.rules';
import { PlannedCorridor } from '../routing/routing.rules';

/** RNF-08: en vuelo el snapshot sale cada 2 s. */
export const TICK_MS = 2_000;

export const TAKEOFF_MS = 20_000;
export const TRANSITION_MS = 10_000;
export const DESCENT_MS = 15_000;
export const LANDING_MS = 15_000;

/** Porcentajes fijos de la fase. El crucero gasta según el alcance del modelo. */
export const TAKEOFF_BATTERY_PERCENT = 3;
export const TRANSITION_BATTERY_PERCENT = 1;
export const DESCENT_BATTERY_PERCENT = 1;
export const LANDING_BATTERY_PERCENT = 3;

export const CRITICAL_BATTERY_PERCENT = 20;

/** RF-17: rango de la cadena de frío y la lectura estable dentro de él. */
export const COLD_CHAIN_RANGE_C = { min: 2, max: 8 } as const;
export const COLD_CHAIN_TEMPERATURE_C = 5;
/** Desde la falla, la carga se calienta hasta salir de rango en ~2 min. */
export const COLD_CHAIN_RISE_C_PER_MIN = 1.5;
export const COLD_CHAIN_MAX_C = 20;
/** Uno de cada diez vuelos con frío sufre una falla. */
export const DEFAULT_COLD_CHAIN_FAILURE_RATE = 0.1;
export const SIMULATED_LATENCY_MS = 40;

export const FLIGHT_NOT_READY = 'No hay un corredor para este pedido.';

const EARTH_RADIUS_KM = 6371;

export enum FlightPhase {
  TAKEOFF = 'takeoff',
  TRANSITION = 'transition',
  CRUISE = 'cruise',
  DESCENT = 'descent',
  LANDING = 'landing',
  LANDED = 'landed',
  /** En destino, ya entregado: espera a que retiren el medicamento. */
  UNLOADING = 'unloading',
}

const PHASE_SEQUENCE: FlightPhase[] = [
  FlightPhase.TAKEOFF,
  FlightPhase.TRANSITION,
  FlightPhase.CRUISE,
  FlightPhase.DESCENT,
  FlightPhase.LANDING,
  FlightPhase.LANDED,
];

export type FlightAlertKind = 'battery_critical' | 'failure' | 'cold_chain';

export type FlightProgress = {
  phase: FlightPhase;
  phaseElapsedMs: number;
  cruiseKm: number;
  batteryPercent: number;
  batteryAlertSent: boolean;
  failureAlertSent: boolean;
  /** Ms desde la confirmación de carga en que falla el frío, o `null`. */
  coldChainExcursionAtMs: number | null;
  coldChainAlertSent: boolean;
  orderStatus: OrderStatus;
};

export type FlightModel = {
  maxSpeedKmh: number;
  maxRangeKm: number;
};

export type FlightStep = {
  progress: FlightProgress;
  latitude: number;
  longitude: number;
  altitudeM: number;
  speedKmh: number;
  etaSeconds: number | null;
  statusChanges: OrderStatus[];
  alerts: FlightAlertKind[];
};

export type LiveFlight = {
  orderId: string;
  droneId: string;
  identifier: string;
  latitude: number;
  longitude: number;
  altitudeM: number;
  speedKmh: number;
  batteryPercent: number;
  payloadKg: number;
  temperatureC: number | null;
  latencyMs: number;
  phase: FlightPhase;
  leg: RouteLeg;
  status: OrderStatus;
  etaSeconds: number | null;
  progress: FlightProgress;
};

type LngLat = {
  longitude: number;
  latitude: number;
};

export function initialProgress(): FlightProgress {
  return {
    phase: FlightPhase.TAKEOFF,
    phaseElapsedMs: 0,
    cruiseKm: 0,
    batteryPercent: 100,
    batteryAlertSent: false,
    failureAlertSent: false,
    coldChainExcursionAtMs: null,
    coldChainAlertSent: false,
    orderStatus: OrderStatus.PENDING_LOAD,
  };
}

/**
 * El regreso arranca con la batería y las alertas con que terminó la ida:
 * el dron no se recarga en el aire, y la carga sigue tan caliente como venía.
 */
export function returnProgress(
  outbound: FlightProgress | null,
): FlightProgress {
  return {
    ...initialProgress(),
    batteryPercent: outbound?.batteryPercent ?? 100,
    batteryAlertSent: outbound?.batteryAlertSent ?? false,
    failureAlertSent: outbound?.failureAlertSent ?? false,
    coldChainExcursionAtMs: outbound?.coldChainExcursionAtMs ?? null,
    coldChainAlertSent: outbound?.coldChainAlertSent ?? false,
    orderStatus: OrderStatus.RETURNING,
  };
}

/** Sin confirmación de carga no hay tick. El objeto de entrada no se muta. */
export function advanceFlight(input: {
  leg?: RouteLeg;
  progress: FlightProgress;
  elapsedMs: number;
  corridor: PlannedCorridor;
  model: FlightModel;
  loadConfirmedAt: Date | null;
}): FlightStep | null {
  if (input.loadConfirmedAt == null) {
    return null;
  }
  const progress: FlightProgress = { ...input.progress };
  const alerts: FlightAlertKind[] = [];
  const statusChanges: OrderStatus[] = [];
  const leg = input.leg ?? RouteLeg.OUTBOUND;
  let elapsed = input.elapsedMs;
  if (
    elapsed > 0 &&
    progress.phase !== FlightPhase.LANDED &&
    progress.orderStatus === OrderStatus.PENDING_LOAD
  ) {
    progress.orderStatus = OrderStatus.IN_FLIGHT;
    statusChanges.push(OrderStatus.IN_FLIGHT);
  }
  while (elapsed > 0 && progress.phase !== FlightPhase.LANDED) {
    const duration = phaseDurationMs(
      progress.phase,
      input.corridor,
      input.model,
    );
    const remaining = duration - progress.phaseElapsedMs;
    if (remaining <= 0) {
      finishPhase(progress, statusChanges, leg);
      continue;
    }
    const step = Math.min(elapsed, remaining);
    applyStep(progress, step, duration, input.corridor, input.model, alerts);
    progress.phaseElapsedMs += step;
    elapsed -= step;
    if (progress.phaseElapsedMs >= duration) {
      finishPhase(progress, statusChanges, leg);
    }
  }
  const pose = poseOf(progress, input.corridor, input.model);
  return { progress, ...pose, statusChanges, alerts };
}

export function buildLiveFlight(input: {
  leg?: RouteLeg;
  orderId: string;
  droneId: string;
  identifier: string;
  quantity: number;
  requiresColdChain: boolean;
  /** Lectura de `coldChainReading`; sin ella, la estable. */
  temperatureC?: number | null;
  step: FlightStep;
}): LiveFlight {
  return {
    orderId: input.orderId,
    droneId: input.droneId,
    identifier: input.identifier,
    latitude: input.step.latitude,
    longitude: input.step.longitude,
    altitudeM: input.step.altitudeM,
    speedKmh: input.step.speedKmh,
    batteryPercent: roundTo(input.step.progress.batteryPercent, 1),
    payloadKg: roundTo(input.quantity * UNIT_MASS_KG, 1),
    temperatureC: input.requiresColdChain
      ? (input.temperatureC ?? COLD_CHAIN_TEMPERATURE_C)
      : null,
    latencyMs: SIMULATED_LATENCY_MS,
    phase: input.step.progress.phase,
    leg: input.leg ?? RouteLeg.OUTBOUND,
    status: input.step.progress.orderStatus,
    etaSeconds: input.step.etaSeconds,
    progress: input.step.progress,
  };
}

/**
 * `COLD_CHAIN_FAILURE_RATE` (0 a 1) fija la probabilidad en pruebas y en la
 * demo; sin variable, o con un valor fuera de rango, es 10 %.
 */
export function coldChainFailureRate(): number {
  const raw = process.env.COLD_CHAIN_FAILURE_RATE;
  const configured = raw === undefined || raw === '' ? NaN : Number(raw);
  return configured >= 0 && configured <= 1
    ? configured
    : DEFAULT_COLD_CHAIN_FAILURE_RATE;
}

/**
 * Se decide una vez, al despegar. Con un solo número aleatorio: por debajo
 * de la tasa hay falla, y en qué punto de la ida cae sale del mismo número.
 */
export function planColdChainExcursion(
  random: number,
  rate: number,
  windowMs: number,
): number | null {
  if (rate <= 0 || random >= rate) {
    return null;
  }
  return Math.floor((random / rate) * windowMs);
}

/** Temperatura de la carga a `elapsedMs` de confirmar la carga. */
export function temperatureAt(
  elapsedMs: number,
  excursionAtMs: number | null,
): number {
  // Un vaivén leve para que la lectura no parezca congelada.
  const stable = COLD_CHAIN_TEMPERATURE_C + 0.3 * Math.sin(elapsedMs / 90_000);
  if (excursionAtMs == null || elapsedMs < excursionAtMs) {
    return roundTo(stable, 1);
  }
  const minutes = (elapsedMs - excursionAtMs) / 60_000;
  return roundTo(
    Math.min(COLD_CHAIN_MAX_C, stable + COLD_CHAIN_RISE_C_PER_MIN * minutes),
    1,
  );
}

export function isOutOfColdChainRange(temperatureC: number): boolean {
  return (
    temperatureC < COLD_CHAIN_RANGE_C.min ||
    temperatureC > COLD_CHAIN_RANGE_C.max
  );
}

/**
 * CU-30: compara en ida, espera y retorno. La alerta sale una sola vez por
 * pedido; después la marca queda en el progreso.
 */
export function coldChainReading(
  progress: Pick<
    FlightProgress,
    'coldChainExcursionAtMs' | 'coldChainAlertSent'
  >,
  elapsedMs: number,
): { temperatureC: number; alert: boolean; alertSent: boolean } {
  const temperatureC = temperatureAt(
    elapsedMs,
    progress.coldChainExcursionAtMs ?? null,
  );
  const alreadySent = progress.coldChainAlertSent === true;
  const alert = !alreadySent && isOutOfColdChainRange(temperatureC);
  return { temperatureC, alert, alertSent: alreadySent || alert };
}

/** Duración de la ida completa, de despegar a aterrizar. */
export function outboundDurationMs(
  corridor: PlannedCorridor,
  model: FlightModel,
): number {
  return PHASE_SEQUENCE.reduce(
    (total, phase) => total + phaseDurationMs(phase, corridor, model),
    0,
  );
}

function finishPhase(
  progress: FlightProgress,
  statusChanges: OrderStatus[],
  leg: RouteLeg,
): void {
  const finished = progress.phase;
  const index = PHASE_SEQUENCE.indexOf(finished);
  progress.phase = PHASE_SEQUENCE[index + 1] ?? FlightPhase.LANDED;
  progress.phaseElapsedMs = 0;
  if (finished === FlightPhase.LANDING) {
    const arrived =
      leg === RouteLeg.RETURN
        ? OrderStatus.RETURNED
        : OrderStatus.AWAITING_DELIVERY;
    progress.orderStatus = arrived;
    statusChanges.push(arrived);
  }
}

function applyStep(
  progress: FlightProgress,
  stepMs: number,
  durationMs: number,
  corridor: PlannedCorridor,
  model: FlightModel,
  alerts: FlightAlertKind[],
): void {
  if (progress.phase === FlightPhase.CRUISE) {
    const km = (model.maxSpeedKmh * stepMs) / 3_600_000;
    const room = Math.max(0, corridor.distanceKm - progress.cruiseKm);
    const flown = Math.min(km, room);
    progress.cruiseKm += flown;
    const drain = model.maxRangeKm > 0 ? (flown / model.maxRangeKm) * 100 : 100;
    burn(progress, drain, alerts);
    return;
  }
  const cost = phaseBatteryPercent(progress.phase);
  burn(progress, durationMs > 0 ? cost * (stepMs / durationMs) : cost, alerts);
}

function burn(
  progress: FlightProgress,
  amount: number,
  alerts: FlightAlertKind[],
): void {
  if (amount <= 0) {
    return;
  }
  const next = Math.max(0, progress.batteryPercent - amount);
  const stored = next <= 0.000_001 ? 0 : next;
  if (
    !progress.batteryAlertSent &&
    progress.batteryPercent > CRITICAL_BATTERY_PERCENT &&
    stored <= CRITICAL_BATTERY_PERCENT
  ) {
    progress.batteryAlertSent = true;
    alerts.push('battery_critical');
  }
  if (
    !progress.failureAlertSent &&
    progress.batteryPercent > 0 &&
    stored === 0
  ) {
    progress.failureAlertSent = true;
    alerts.push('failure');
  }
  progress.batteryPercent = stored;
}

function phaseDurationMs(
  phase: FlightPhase,
  corridor: PlannedCorridor,
  model: FlightModel,
): number {
  switch (phase) {
    case FlightPhase.TAKEOFF:
      return TAKEOFF_MS;
    case FlightPhase.TRANSITION:
      return TRANSITION_MS;
    case FlightPhase.CRUISE:
      if (model.maxSpeedKmh <= 0) {
        return 0;
      }
      return (corridor.distanceKm / model.maxSpeedKmh) * 3_600_000;
    case FlightPhase.DESCENT:
      return DESCENT_MS;
    case FlightPhase.LANDING:
      return LANDING_MS;
    default:
      return 0;
  }
}

function phaseBatteryPercent(phase: FlightPhase): number {
  switch (phase) {
    case FlightPhase.TAKEOFF:
      return TAKEOFF_BATTERY_PERCENT;
    case FlightPhase.TRANSITION:
      return TRANSITION_BATTERY_PERCENT;
    case FlightPhase.DESCENT:
      return DESCENT_BATTERY_PERCENT;
    case FlightPhase.LANDING:
      return LANDING_BATTERY_PERCENT;
    default:
      return 0;
  }
}

function poseOf(
  progress: FlightProgress,
  corridor: PlannedCorridor,
  model: FlightModel,
): Pick<
  FlightStep,
  'latitude' | 'longitude' | 'altitudeM' | 'speedKmh' | 'etaSeconds'
> {
  const origin = pointOf(corridor.coordinates, 0);
  const destination = pointOf(
    corridor.coordinates,
    Math.max(0, corridor.coordinates.length - 1),
  );
  const altitude = corridor.altitudeM;
  let point = origin;
  let altitudeM = 0;
  let speedKmh = 0;
  switch (progress.phase) {
    case FlightPhase.TAKEOFF:
      altitudeM = altitude * (progress.phaseElapsedMs / TAKEOFF_MS);
      point = origin;
      break;
    case FlightPhase.TRANSITION:
      altitudeM = altitude;
      point = origin;
      speedKmh = model.maxSpeedKmh / 2;
      break;
    case FlightPhase.CRUISE:
      altitudeM = altitude;
      point = pointAt(corridor.coordinates, progress.cruiseKm);
      speedKmh = model.maxSpeedKmh;
      break;
    case FlightPhase.DESCENT:
      altitudeM = altitude * (1 - progress.phaseElapsedMs / DESCENT_MS);
      point = destination;
      speedKmh = model.maxSpeedKmh / 2;
      break;
    default:
      point = destination;
      altitudeM = 0;
      speedKmh = 0;
  }
  return {
    latitude: roundTo(point.latitude, 6),
    longitude: roundTo(point.longitude, 6),
    altitudeM: roundTo(altitudeM, 1),
    speedKmh: roundTo(speedKmh, 1),
    etaSeconds: etaSeconds(progress, corridor, model),
  };
}

function etaSeconds(
  progress: FlightProgress,
  corridor: PlannedCorridor,
  model: FlightModel,
): number | null {
  if (progress.phase === FlightPhase.LANDED) {
    return null;
  }
  const phases = PHASE_SEQUENCE.filter((phase) => phase !== FlightPhase.LANDED);
  const start = phases.indexOf(progress.phase);
  let remainingMs = 0;
  for (let index = start; index < phases.length; index += 1) {
    const duration = phaseDurationMs(phases[index], corridor, model);
    remainingMs +=
      phases[index] === progress.phase
        ? Math.max(0, duration - progress.phaseElapsedMs)
        : duration;
  }
  return Math.ceil(remainingMs / 1000);
}

function pointAt(
  coordinates: Array<[number, number]>,
  distanceKm: number,
): LngLat {
  if (!coordinates.length) {
    return { longitude: 0, latitude: 0 };
  }
  if (distanceKm <= 0) {
    return toLngLat(coordinates[0]);
  }
  let remaining = distanceKm;
  for (let index = 1; index < coordinates.length; index += 1) {
    const start = toLngLat(coordinates[index - 1]);
    const end = toLngLat(coordinates[index]);
    const segment = haversineKm(start, end);
    if (remaining <= segment || index === coordinates.length - 1) {
      const ratio = segment === 0 ? 1 : Math.min(1, remaining / segment);
      return {
        longitude: start.longitude + (end.longitude - start.longitude) * ratio,
        latitude: start.latitude + (end.latitude - start.latitude) * ratio,
      };
    }
    remaining -= segment;
  }
  return toLngLat(coordinates[coordinates.length - 1]);
}

function pointOf(coordinates: Array<[number, number]>, index: number): LngLat {
  const pair = coordinates[index];
  return pair ? toLngLat(pair) : { longitude: 0, latitude: 0 };
}

function toLngLat(pair: [number, number]): LngLat {
  return { longitude: pair[0], latitude: pair[1] };
}

function haversineKm(start: LngLat, end: LngLat): number {
  const toRadians = (degrees: number) => (degrees * Math.PI) / 180;
  const latitudeDelta = toRadians(end.latitude - start.latitude);
  const longitudeDelta = toRadians(end.longitude - start.longitude);
  const startLat = toRadians(start.latitude);
  const endLat = toRadians(end.latitude);
  const haversine =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(startLat) * Math.cos(endLat) * Math.sin(longitudeDelta / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(haversine)));
}

function roundTo(value: number, digits: number): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}
