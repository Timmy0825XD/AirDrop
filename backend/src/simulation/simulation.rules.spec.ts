import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { PlannedCorridor } from '../routing/routing.rules';
import {
  COLD_CHAIN_RANGE_C,
  DEFAULT_COLD_CHAIN_FAILURE_RATE,
  FlightPhase,
  advanceFlight,
  buildLiveFlight,
  coldChainFailureRate,
  coldChainReading,
  initialProgress,
  isOutOfColdChainRange,
  outboundDurationMs,
  planColdChainExcursion,
  returnProgress,
  temperatureAt,
} from './simulation.rules';

const confirmed = new Date('2026-10-11T18:00:00.000Z');

const corridor: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 10,
  coordinates: [
    [-73.26, 10.47],
    [-73.2, 10.5],
  ],
};

const model = { maxSpeedKmh: 150, maxRangeKm: 110 };

describe('advanceFlight', () => {
  it('does not tick before the load is confirmed', () => {
    const step = advanceFlight({
      progress: initialProgress(),
      elapsedMs: 2_000,
      corridor,
      model,
      loadConfirmedAt: null,
    });
    expect(step).toBeNull();
  });

  it('spends more battery on the vertical phase than in cruise over the same time', () => {
    const takeoff = advanceFlight({
      progress: initialProgress(),
      elapsedMs: 2_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    const cruise = advanceFlight({
      progress: {
        ...initialProgress(),
        phase: FlightPhase.CRUISE,
        orderStatus: OrderStatus.IN_FLIGHT,
      },
      elapsedMs: 2_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(takeoff).not.toBeNull();
    expect(cruise).not.toBeNull();
    const takeoffDrop = 100 - takeoff!.progress.batteryPercent;
    const cruiseDrop = 100 - cruise!.progress.batteryPercent;
    expect(takeoffDrop).toBeGreaterThan(cruiseDrop);
  });

  it('moves along the corridor and finishes awaiting delivery', () => {
    const started = advanceFlight({
      progress: initialProgress(),
      elapsedMs: 35_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(started).not.toBeNull();
    expect(started!.statusChanges).toContain(OrderStatus.IN_FLIGHT);
    expect(started!.progress.phase).toBe(FlightPhase.CRUISE);
    expect(started!.longitude).toBeGreaterThan(-73.26);

    let progress = started!.progress;
    let last = started!;
    for (
      let tick = 0;
      tick < 200 && last.progress.phase !== FlightPhase.LANDED;
      tick += 1
    ) {
      const step = advanceFlight({
        progress,
        elapsedMs: 2_000,
        corridor,
        model,
        loadConfirmedAt: confirmed,
      });
      expect(step).not.toBeNull();
      last = step!;
      progress = step!.progress;
    }
    expect(last.progress.phase).toBe(FlightPhase.LANDED);
    expect(last.progress.orderStatus).toBe(OrderStatus.AWAITING_DELIVERY);
    expect(last.statusChanges).toContain(OrderStatus.AWAITING_DELIVERY);
    expect(last.latitude).toBeCloseTo(10.5, 5);
    expect(last.longitude).toBeCloseTo(-73.2, 5);
    expect(last.etaSeconds).toBeNull();
  });

  it('emits the critical battery and failure alerts only once', () => {
    const critical = advanceFlight({
      progress: { ...initialProgress(), batteryPercent: 21 },
      elapsedMs: 20_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(critical!.alerts).toEqual(['battery_critical']);
    const criticalAgain = advanceFlight({
      progress: critical!.progress,
      elapsedMs: 20_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(criticalAgain!.alerts).not.toContain('battery_critical');

    const failure = advanceFlight({
      progress: { ...initialProgress(), batteryPercent: 2 },
      elapsedMs: 20_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(failure!.alerts).toEqual(['failure']);
    const failureAgain = advanceFlight({
      progress: failure!.progress,
      elapsedMs: 20_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(failureAgain!.alerts).not.toContain('failure');
  });
});

describe('vuelo de regreso', () => {
  it('termina en returned, no en awaiting_delivery', () => {
    const step = advanceFlight({
      leg: RouteLeg.RETURN,
      progress: returnProgress(null),
      elapsedMs: 3_600_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(step?.progress.phase).toBe(FlightPhase.LANDED);
    expect(step?.progress.orderStatus).toBe(OrderStatus.RETURNED);
    expect(step?.statusChanges).toEqual([OrderStatus.RETURNED]);
  });

  it('mantiene returning mientras vuela', () => {
    const step = advanceFlight({
      leg: RouteLeg.RETURN,
      progress: returnProgress(null),
      elapsedMs: 2_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    });
    expect(step?.progress.orderStatus).toBe(OrderStatus.RETURNING);
    expect(step?.statusChanges).toEqual([]);
  });

  it('sigue con la batería con que terminó la ida', () => {
    const outbound = {
      ...initialProgress(),
      batteryPercent: 62,
      batteryAlertSent: true,
    };
    const progress = returnProgress(outbound);
    expect(progress.batteryPercent).toBe(62);
    expect(progress.batteryAlertSent).toBe(true);
    expect(progress.phase).toBe(FlightPhase.TAKEOFF);
    expect(progress.orderStatus).toBe(OrderStatus.RETURNING);
  });

  it('publica la telemetría con el tramo de regreso', () => {
    const step = advanceFlight({
      leg: RouteLeg.RETURN,
      progress: returnProgress(null),
      elapsedMs: 2_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    })!;
    const live = buildLiveFlight({
      leg: RouteLeg.RETURN,
      orderId: 'o',
      droneId: 'd',
      identifier: 'WG-1',
      quantity: 1,
      requiresColdChain: false,
      step,
    });
    expect(live.leg).toBe(RouteLeg.RETURN);
    expect(live.status).toBe(OrderStatus.RETURNING);
  });
});

describe('cadena de frío (RF-17)', () => {
  const minute = 60_000;

  it('con tasa 0 nunca hay falla y la carga se queda en rango', () => {
    expect(planColdChainExcursion(0, 0, 10 * minute)).toBeNull();
    for (let elapsed = 0; elapsed <= 60 * minute; elapsed += minute) {
      expect(isOutOfColdChainRange(temperatureAt(elapsed, null))).toBe(false);
    }
  });

  it('con tasa 1 la falla cae dentro de la ida y la carga sale de rango', () => {
    const window = 10 * minute;
    const at = planColdChainExcursion(0.5, 1, window);
    expect(at).toBe(5 * minute);
    expect(isOutOfColdChainRange(temperatureAt(at! + minute, at))).toBe(false);
    expect(isOutOfColdChainRange(temperatureAt(at! + 3 * minute, at))).toBe(
      true,
    );
  });

  it('con la tasa por defecto, uno de cada diez números cae en falla', () => {
    expect(planColdChainExcursion(0.09, 0.1, minute)).not.toBeNull();
    expect(planColdChainExcursion(0.1, 0.1, minute)).toBeNull();
  });

  it('después de la falla la temperatura no baja', () => {
    let previous = -Infinity;
    for (let elapsed = minute; elapsed <= 20 * minute; elapsed += 10_000) {
      const reading = temperatureAt(elapsed, minute);
      expect(reading).toBeGreaterThanOrEqual(previous);
      previous = reading;
    }
    expect(previous).toBeGreaterThan(COLD_CHAIN_RANGE_C.max);
  });

  it('alerta una sola vez', () => {
    const progress = { coldChainExcursionAtMs: 0, coldChainAlertSent: false };
    const first = coldChainReading(progress, 10 * minute);
    expect(first.alert).toBe(true);
    const second = coldChainReading(
      { ...progress, coldChainAlertSent: first.alertSent },
      11 * minute,
    );
    expect(second.alert).toBe(false);
    expect(second.alertSent).toBe(true);
  });

  it('el regreso hereda la falla y la alerta de la ida', () => {
    const progress = returnProgress({
      ...initialProgress(),
      coldChainExcursionAtMs: 1234,
      coldChainAlertSent: true,
    });
    expect(progress.coldChainExcursionAtMs).toBe(1234);
    expect(progress.coldChainAlertSent).toBe(true);
  });

  it('lee COLD_CHAIN_FAILURE_RATE y vuelve al 10 % si no sirve', () => {
    const previous = process.env.COLD_CHAIN_FAILURE_RATE;
    process.env.COLD_CHAIN_FAILURE_RATE = '1';
    expect(coldChainFailureRate()).toBe(1);
    process.env.COLD_CHAIN_FAILURE_RATE = '0';
    expect(coldChainFailureRate()).toBe(0);
    process.env.COLD_CHAIN_FAILURE_RATE = '7';
    expect(coldChainFailureRate()).toBe(DEFAULT_COLD_CHAIN_FAILURE_RATE);
    delete process.env.COLD_CHAIN_FAILURE_RATE;
    expect(coldChainFailureRate()).toBe(DEFAULT_COLD_CHAIN_FAILURE_RATE);
    process.env.COLD_CHAIN_FAILURE_RATE = previous;
  });

  it('la ida dura lo de sus fases más el crucero', () => {
    // 20 + 10 + 15 + 15 s de fases fijas y 10 km a 150 km/h (240 s).
    expect(outboundDurationMs(corridor, model)).toBe(300_000);
  });

  it('sin frío no publica temperatura; con frío publica la lectura', () => {
    const step = advanceFlight({
      progress: initialProgress(),
      elapsedMs: 2_000,
      corridor,
      model,
      loadConfirmedAt: confirmed,
    })!;
    const base = {
      orderId: 'o',
      droneId: 'd',
      identifier: 'WG-1',
      quantity: 1,
      step,
    };
    expect(
      buildLiveFlight({ ...base, requiresColdChain: false, temperatureC: 9 })
        .temperatureC,
    ).toBeNull();
    expect(
      buildLiveFlight({ ...base, requiresColdChain: true, temperatureC: 9 })
        .temperatureC,
    ).toBe(9);
  });
});
