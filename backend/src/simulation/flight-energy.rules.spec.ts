import { RouteLeg } from '../common/enums/route-leg.enum';
import { PlannedCorridor } from '../routing/routing.rules';
import {
  CRITICAL_BATTERY_PERCENT,
  VERTICAL_BATTERY_PER_LEG,
  batteryNow,
  legBatteryPercent,
  maxOneWayKm,
  missionBatteryPercent,
  rechargePercentPerMin,
} from './flight-energy.rules';
import {
  FlightAlertKind,
  FlightPhase,
  advanceFlight,
  initialProgress,
  returnProgress,
} from './simulation.rules';

const wingcopter = { maxSpeedKmh: 150, maxRangeKm: 110 };
const confirmed = new Date('2026-11-02T15:00:00.000Z');

function corridorOf(distanceKm: number): PlannedCorridor {
  return {
    altitudeM: 100,
    distanceKm,
    coordinates: [
      [-73.25, 10.46],
      [-73.25, 10.46 + distanceKm / 111.19],
    ],
  };
}

/** Ida y regreso completos con el reloj real del simulador. */
function flyRoundTrip(distanceKm: number) {
  const corridor = corridorOf(distanceKm);
  const alerts: FlightAlertKind[] = [];
  const outbound = advanceFlight({
    progress: initialProgress(),
    elapsedMs: 3_600_000,
    corridor,
    model: wingcopter,
    loadConfirmedAt: confirmed,
  });
  alerts.push(...(outbound?.alerts ?? []));
  const back = advanceFlight({
    leg: RouteLeg.RETURN,
    progress: returnProgress(outbound?.progress ?? null),
    elapsedMs: 3_600_000,
    corridor,
    model: wingcopter,
    loadConfirmedAt: confirmed,
  });
  alerts.push(...(back?.alerts ?? []));
  return { landed: back?.progress, alerts };
}

describe('cuenta de energía (RF-11)', () => {
  it('cobra 8 % de fases verticales por tramo', () => {
    expect(VERTICAL_BATTERY_PER_LEG).toBe(8);
    expect(legBatteryPercent(0, 110)).toBe(8);
  });

  it('con la batería llena, la ida más larga del Wingcopter 198 es 35,2 km', () => {
    expect(maxOneWayKm(110)).toBeCloseTo(35.2, 5);
    expect(missionBatteryPercent(35.2, 110)).toBeCloseTo(100, 5);
  });

  it('a 35 km ida y vuelta aterriza con la reserva y sin alerta crítica', () => {
    const { landed, alerts } = flyRoundTrip(35);
    expect(landed?.phase).toBe(FlightPhase.LANDED);
    expect(landed?.batteryPercent).toBeGreaterThan(CRITICAL_BATTERY_PERCENT);
    expect(alerts).toEqual([]);
  });

  it('a 50 km, que antes se aceptaba, el dron se queda sin batería al volver', () => {
    const { landed, alerts } = flyRoundTrip(50);
    expect(landed?.batteryPercent).toBe(0);
    expect(alerts).toEqual(['battery_critical', 'failure']);
  });

  it('la decisión y el simulador dan el mismo gasto', () => {
    const { landed } = flyRoundTrip(30);
    const spent = missionBatteryPercent(30, 110) - CRITICAL_BATTERY_PERCENT;
    expect(100 - (landed?.batteryPercent ?? 0)).toBeCloseTo(spent, 5);
  });
});

describe('recarga en tierra', () => {
  const landed = new Date('2026-11-02T15:00:00.000Z');
  const later = (minutes: number) =>
    new Date(landed.getTime() + minutes * 60_000);

  it('recarga 1,5 % por minuto desde que aterrizó', () => {
    expect(batteryNow(40, landed, later(10))).toBe(55);
  });

  it('nunca pasa de 100 %', () => {
    expect(batteryNow(40, landed, later(120))).toBe(100);
  });

  it('un dron que nunca ha volado está lleno', () => {
    expect(batteryNow(100, null, later(0))).toBe(100);
  });

  it('DRONE_RECHARGE_PERCENT_PER_MIN acelera la recarga en una demostración', () => {
    process.env.DRONE_RECHARGE_PERCENT_PER_MIN = '10';
    try {
      expect(rechargePercentPerMin()).toBe(10);
      expect(batteryNow(40, landed, later(3))).toBe(70);
    } finally {
      delete process.env.DRONE_RECHARGE_PERCENT_PER_MIN;
    }
    expect(rechargePercentPerMin()).toBe(1.5);
  });
});
