import { User } from '../../users/user.entity';
import { isLockActive } from '../../auth/auth.rules';
import { isDeliveryWaitOver } from '../../delivery/delivery.rules';
import { Order } from '../../orders/order.entity';
import {
  advanceFlight,
  initialProgress,
  outboundDurationMs,
  TICK_MS,
  FlightPhase,
} from '../../simulation/simulation.rules';
import { PlannedCorridor } from '../../routing/routing.rules';
import { SimClock, simClock } from './sim-clock';
import { SimTimeSubscriber } from './sim-time.subscriber';

const NOW = new Date('2026-11-05T15:00:00.000Z');

const corridor: PlannedCorridor = {
  coordinates: [
    [-73.25, 10.46],
    [-73.2, 10.5],
  ],
  distanceKm: 7,
  altitudeM: 120,
};
const model = { maxSpeedKmh: 150, maxRangeKm: 110 };

/** Ticks del reloj de vuelo hasta aterrizar, con el tiempo de cada tick. */
function ticksToLand(tickMs: number): number {
  let progress = initialProgress();
  let ticks = 0;
  while (progress.phase !== FlightPhase.LANDED && ticks < 10_000) {
    const step = advanceFlight({
      progress,
      elapsedMs: tickMs,
      corridor,
      model,
      loadConfirmedAt: NOW,
    });
    progress = step!.progress;
    ticks += 1;
  }
  return ticks;
}

describe('SimClock (RF-31)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('a x1 da la misma hora que Date.now(), también con relojes falsos', () => {
    const clock = new SimClock();
    jest.advanceTimersByTime(90_000);
    expect(clock.nowMs()).toBe(Date.now());
  });

  it('a x2 el vuelo dura la mitad de ticks', () => {
    const clock = new SimClock();
    const atX1 = ticksToLand(clock.scale(TICK_MS));
    clock.change({ speed: 2 });
    const atX2 = ticksToLand(clock.scale(TICK_MS));
    expect(outboundDurationMs(corridor, model)).toBeGreaterThan(0);
    expect(atX2).toBe(Math.ceil(atX1 / 2));
  });

  it('en pausa el tick no mueve al dron', () => {
    const clock = new SimClock();
    clock.change({ paused: true });
    const step = advanceFlight({
      progress: initialProgress(),
      elapsedMs: clock.scale(TICK_MS),
      corridor,
      model,
      loadConfirmedAt: NOW,
    });
    expect(step!.progress.phase).toBe(FlightPhase.TAKEOFF);
    expect(step!.progress.phaseElapsedMs).toBe(0);
  });

  it('a x8 los 5 minutos del código vencen en 37,5 s reales', () => {
    const clock = new SimClock();
    const landedAt = clock.now();
    clock.change({ speed: 8 });
    jest.advanceTimersByTime(37_000);
    expect(isDeliveryWaitOver(landedAt, clock.now())).toBe(false);
    jest.advanceTimersByTime(500);
    expect(isDeliveryWaitOver(landedAt, clock.now())).toBe(true);
  });

  it('el bloqueo del login sigue en hora real aunque el reloj vaya a x8', () => {
    simClock.change({ speed: 8 });
    const user = {
      lockedUntil: new Date(NOW.getTime() + 15 * 60_000),
    } as User;
    jest.advanceTimersByTime(2 * 60_000);
    // 16 min simulados después, pero solo 2 reales: sigue bloqueado.
    expect(simClock.nowMs() - NOW.getTime()).toBe(16 * 60_000);
    expect(isLockActive(user)).toBe(true);
  });

  it('un barrido cada minuto simulado corre cada 7,5 s reales a x8 y no corre en pausa', () => {
    const clock = new SimClock();
    clock.change({ speed: 8 });
    const task = jest.fn();
    const timer = clock.every(60_000, task);
    jest.advanceTimersByTime(8_000);
    expect(task).toHaveBeenCalledTimes(1);
    clock.change({ paused: true });
    jest.advanceTimersByTime(60_000);
    expect(task).toHaveBeenCalledTimes(1);
    clearInterval(timer);
  });

  it('si el reloj vuelve a la hora real, el barrido no se queda esperando', () => {
    const clock = new SimClock();
    clock.change({ speed: 8 });
    jest.advanceTimersByTime(60_000);
    const task = jest.fn();
    const timer = clock.every(60_000, task);
    clock.resetToRealTime();
    jest.advanceTimersByTime(62_000);
    expect(task).toHaveBeenCalledTimes(1);
    clearInterval(timer);
  });
});

describe('SimTimeSubscriber (RF-31)', () => {
  const metadataOf = (target: unknown) => ({
    target,
    createDateColumn: {
      getEntityValue: (entity: { createdAt?: Date }) => entity.createdAt,
      setEntityValue: (entity: { createdAt?: Date }, value: Date) => {
        entity.createdAt = value;
      },
    },
  });
  const subscriber = new SimTimeSubscriber({ subscribers: [] } as never);

  beforeEach(() => {
    jest.useFakeTimers({ now: NOW });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('la fecha de creación de un pedido es la simulada', () => {
    simClock.change({ speed: 8 });
    jest.advanceTimersByTime(60_000);
    const order: { createdAt?: Date } = {};
    subscriber.beforeInsert({
      entity: order,
      metadata: metadataOf(Order),
    } as never);
    expect(order.createdAt?.getTime()).toBe(NOW.getTime() + 8 * 60_000);
  });

  it('la de una cuenta es la real', () => {
    simClock.change({ speed: 8 });
    jest.advanceTimersByTime(60_000);
    const user: { createdAt?: Date } = {};
    subscriber.beforeInsert({
      entity: user,
      metadata: metadataOf(User),
    } as never);
    expect(user.createdAt).toBeUndefined();
  });
});
