import { OrderStatus } from '../common/enums/order-status.enum';
import { PlannedCorridor } from '../routing/routing.rules';
import {
  FlightPhase,
  advanceFlight,
  initialProgress,
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
