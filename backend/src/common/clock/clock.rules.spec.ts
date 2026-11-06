import {
  changeClock,
  isClockSpeed,
  parseClockState,
  presentClock,
  realTimeState,
  simElapsedMs,
  simNowMs,
} from './clock.rules';

const T0 = Date.parse('2026-11-05T12:00:00.000Z');
const MINUTE = 60_000;

describe('reloj simulado (RF-31)', () => {
  it('a x1 sin cambios la hora simulada es la real', () => {
    const state = realTimeState(T0);
    expect(simNowMs(state, T0 + 5 * MINUTE)).toBe(T0 + 5 * MINUTE);
  });

  it('a x8, 1 minuto real son 8 simulados', () => {
    const state = changeClock(realTimeState(T0), { speed: 8 }, T0);
    expect(simNowMs(state, T0 + MINUTE)).toBe(T0 + 8 * MINUTE);
  });

  it('cambiar de velocidad no hace saltar la hora', () => {
    const fast = changeClock(realTimeState(T0), { speed: 4 }, T0);
    const before = simNowMs(fast, T0 + MINUTE);
    const slow = changeClock(fast, { speed: 1 }, T0 + MINUTE);
    expect(simNowMs(slow, T0 + MINUTE)).toBe(before);
    expect(simNowMs(slow, T0 + 2 * MINUTE)).toBe(before + MINUTE);
  });

  it('en pausa la hora no avanza y al reanudar sigue desde ahí', () => {
    const fast = changeClock(realTimeState(T0), { speed: 2 }, T0);
    const paused = changeClock(fast, { paused: true }, T0 + MINUTE);
    expect(simNowMs(paused, T0 + 10 * MINUTE)).toBe(T0 + 2 * MINUTE);
    const resumed = changeClock(paused, { paused: false }, T0 + 10 * MINUTE);
    expect(resumed.speed).toBe(2);
    expect(simNowMs(resumed, T0 + 11 * MINUTE)).toBe(T0 + 4 * MINUTE);
  });

  it('el tiempo simulado de un tick depende de la velocidad, y es 0 en pausa', () => {
    const x8 = changeClock(realTimeState(T0), { speed: 8 }, T0);
    expect(simElapsedMs(x8, 2_000)).toBe(16_000);
    expect(simElapsedMs({ ...x8, paused: true }, 2_000)).toBe(0);
  });

  it('solo acepta pausa, x1, x2, x4 y x8', () => {
    expect([1, 2, 4, 8].every(isClockSpeed)).toBe(true);
    expect(isClockSpeed(3)).toBe(false);
    expect(isClockSpeed(16)).toBe(false);
  });

  it('presenta la hora simulada en ISO', () => {
    const state = changeClock(realTimeState(T0), { speed: 2 }, T0);
    expect(presentClock(state, T0 + MINUTE)).toEqual({
      now: new Date(T0 + 2 * MINUTE).toISOString(),
      speed: 2,
      paused: false,
    });
  });

  it('descarta un estado guardado dañado', () => {
    const state = changeClock(realTimeState(T0), { speed: 4 }, T0);
    expect(parseClockState(JSON.stringify(state))).toEqual(state);
    expect(parseClockState(null)).toBeNull();
    expect(parseClockState('{no json')).toBeNull();
    expect(parseClockState(JSON.stringify({ ...state, speed: 5 }))).toBeNull();
  });
});
