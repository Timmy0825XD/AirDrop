/**
 * RF-31: reloj simulado. La hora simulada es la hora en que se fijó la
 * velocidad (el ancla), más el tiempo real transcurrido por la velocidad.
 * Al cambiar de velocidad se ancla en la hora simulada de ese momento, así
 * la hora nunca salta.
 */

export const CLOCK_SPEEDS = [1, 2, 4, 8] as const;

export type ClockSpeed = (typeof CLOCK_SPEEDS)[number];

export type ClockState = {
  anchorSimMs: number;
  anchorRealMs: number;
  speed: ClockSpeed;
  /** En pausa la hora simulada no avanza; la velocidad se guarda para seguir. */
  paused: boolean;
};

export type ClockChange = {
  speed?: ClockSpeed;
  paused?: boolean;
};

/** Lo que ven la web y la app: con esto extrapolan la hora entre avisos. */
export type ClockView = {
  now: string;
  speed: ClockSpeed;
  paused: boolean;
};

export function isClockSpeed(value: unknown): value is ClockSpeed {
  return CLOCK_SPEEDS.includes(value as ClockSpeed);
}

/** x1, sin pausa y sin desfase: la hora simulada es la real. */
export function realTimeState(realNowMs: number): ClockState {
  return {
    anchorSimMs: realNowMs,
    anchorRealMs: realNowMs,
    speed: 1,
    paused: false,
  };
}

export function simNowMs(state: ClockState, realNowMs: number): number {
  if (state.paused) {
    return state.anchorSimMs;
  }
  return state.anchorSimMs + (realNowMs - state.anchorRealMs) * state.speed;
}

export function changeClock(
  state: ClockState,
  change: ClockChange,
  realNowMs: number,
): ClockState {
  return {
    anchorSimMs: simNowMs(state, realNowMs),
    anchorRealMs: realNowMs,
    speed: change.speed ?? state.speed,
    paused: change.paused ?? state.paused,
  };
}

/** Cuánto tiempo simulado cabe en `realMs` reales: 0 en pausa. */
export function simElapsedMs(state: ClockState, realMs: number): number {
  return state.paused ? 0 : realMs * state.speed;
}

export function presentClock(state: ClockState, realNowMs: number): ClockView {
  return {
    now: new Date(simNowMs(state, realNowMs)).toISOString(),
    speed: state.speed,
    paused: state.paused,
  };
}

/** Lo guardado en Redis puede venir de otra versión o dañado. */
export function parseClockState(raw: string | null): ClockState | null {
  if (!raw) {
    return null;
  }
  try {
    const value = JSON.parse(raw) as Partial<ClockState>;
    if (
      typeof value.anchorSimMs === 'number' &&
      typeof value.anchorRealMs === 'number' &&
      isClockSpeed(value.speed) &&
      typeof value.paused === 'boolean'
    ) {
      return value as ClockState;
    }
  } catch {
    return null;
  }
  return null;
}
