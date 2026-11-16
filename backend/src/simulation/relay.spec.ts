import { NODES, DELIVERY_POINTS } from '../airspace/regional-network';
import { AirspaceService } from '../airspace/airspace.service';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { RoutePlannerService } from '../routing/route-planner.service';
import {
  PlannedCorridor,
  haversineKm,
  joinAtRelay,
  reverseCorridor,
} from '../routing/routing.rules';
import {
  FlightPhase,
  RELAY_STOP_MS,
  advanceFlight,
  initialProgress,
  outboundDurationMs,
} from './simulation.rules';

/** RF-55: la escala en el Nodo Valledupar. */

const confirmed = new Date('2026-11-16T15:00:00.000Z');
const model = { maxSpeedKmh: 120, maxRangeKm: 120 };

function leg(from: [number, number], to: [number, number]): PlannedCorridor {
  const km = haversineKm(
    { longitude: from[0], latitude: from[1] },
    { longitude: to[0], latitude: to[1] },
  );
  return {
    altitudeM: 90,
    distanceKm: Math.round(km * 100) / 100,
    coordinates: [from, to],
  };
}
// Unos 10 km hasta el relevo y unos 6 km después.
const first = leg([-73.3, 10.415], [-73.235, 10.479]);
const second = leg([-73.235, 10.479], [-73.205, 10.523]);
const corridor = joinAtRelay(first, second);

function toRelayMs(): number {
  return 30_000 + (first.distanceKm / 120) * 3_600_000 + 1_000;
}

function fly(progress = initialProgress(), elapsedMs = 60 * 60_000) {
  return advanceFlight({
    progress,
    elapsedMs,
    corridor,
    model,
    loadConfirmedAt: confirmed,
  })!;
}

describe('Corredor con escala (RF-55)', () => {
  it('une los dos tramos y sabe dónde está la escala', () => {
    expect(corridor.distanceKm).toBeCloseTo(
      first.distanceKm + second.distanceKm,
      2,
    );
    expect(corridor.relayKm).toBe(first.distanceKm);
    expect(corridor.coordinates).toHaveLength(3);
  });

  it('al revés, la escala queda a la misma distancia del relevo', () => {
    expect(reverseCorridor(corridor).relayKm).toBeCloseTo(second.distanceKm, 2);
  });

  it('la duración de la ida suma la escala', () => {
    const direct = { ...corridor, relayKm: null };
    expect(outboundDurationMs(corridor, model)).toBe(
      outboundDurationMs(direct, model) + RELAY_STOP_MS,
    );
  });
});

describe('Vuelo con escala (RF-55)', () => {
  it('se detiene en el relevo, en tierra', () => {
    // A 120 km/h, 2 km por minuto, más 30 s de despegue y transición.
    const step = fly(initialProgress(), toRelayMs());
    expect(step.progress.phase).toBe(FlightPhase.RELAY);
    expect(step.progress.cruiseKm).toBe(first.distanceKm);
    expect(step.altitudeM).toBe(0);
    expect(step.longitude).toBeCloseTo(-73.235, 3);
    expect(step.latitude).toBeCloseTo(10.479, 3);
  });

  it('sale del relevo con la batería nueva y sigue al destino', () => {
    const atRelay = fly(initialProgress(), toRelayMs()).progress;
    const before = atRelay.batteryPercent;
    const after = fly(atRelay, RELAY_STOP_MS - atRelay.phaseElapsedMs).progress;
    expect(before).toBeLessThan(90);
    expect(after.phase).toBe(FlightPhase.CRUISE);
    expect(after.relayDone).toBe(true);
    expect(after.batteryPercent).toBe(96);
  });

  it('termina en destino y no vuelve a parar en el relevo', () => {
    const step = fly();
    expect(step.progress.phase).toBe(FlightPhase.LANDED);
    expect(step.progress.orderStatus).toBe(OrderStatus.AWAITING_DELIVERY);
    expect(step.progress.relayDone).toBe(true);
  });

  it('el regreso también para en el relevo', () => {
    const back = advanceFlight({
      leg: RouteLeg.RETURN,
      progress: {
        ...initialProgress(),
        orderStatus: OrderStatus.RETURNING,
      },
      elapsedMs: 31_000 + (second.distanceKm / 120) * 3_600_000 + 1_000,
      corridor: reverseCorridor(corridor),
      model,
      loadConfirmedAt: confirmed,
    })!;
    expect(back.progress.phase).toBe(FlightPhase.RELAY);
    expect(back.progress.cruiseKm).toBeCloseTo(second.distanceKm, 2);
  });

  it('la ETA cuenta la escala que falta', () => {
    const start = fly(initialProgress(), 1_000);
    const direct = advanceFlight({
      progress: initialProgress(),
      elapsedMs: 1_000,
      corridor: { ...corridor, relayKm: null },
      model,
      loadConfirmedAt: confirmed,
    })!;
    expect(start.etaSeconds! - direct.etaSeconds!).toBe(RELAY_STOP_MS / 1000);
  });
});

describe('Rutas con escala en la red real (RF-55)', () => {
  const airspace = new AirspaceService();
  const planner = new RoutePlannerService(
    { manager: { query: jest.fn().mockResolvedValue([]) } } as never,
    { stormPolygons: () => [] } as never,
    airspace,
  );
  const patillal = DELIVERY_POINTS.find(
    (point) => point.code === 'dp-patillal',
  )!;

  it('Codazzi → Valledupar → Patillal tiene corredor legal', () => {
    const planned = planner.planWithRelay(
      NODES.codazzi,
      NODES.valledupar,
      patillal,
      airspace.blockingPolygons(),
    )!;
    expect(planned).not.toBeNull();
    expect(planned.relayKm).toBeGreaterThan(40);
  });

  it('el regreso de una ida con escala para en el mismo relevo', () => {
    const outbound = planner.planWithRelay(
      NODES.codazzi,
      NODES.valledupar,
      patillal,
      airspace.blockingPolygons(),
    )!;
    const back = planner.planReturn(
      patillal,
      NODES.codazzi,
      airspace.blockingPolygons(),
      outbound,
    )!;
    expect(back.corridor.relayKm).not.toBeNull();
    const [lng, lat] = back.corridor.coordinates.find(
      ([longitude, latitude]) =>
        Math.abs(longitude - NODES.valledupar.longitude) < 1e-6 &&
        Math.abs(latitude - NODES.valledupar.latitude) < 1e-6,
    )!;
    expect([lng, lat]).toEqual([
      NODES.valledupar.longitude,
      NODES.valledupar.latitude,
    ]);
  });
});
