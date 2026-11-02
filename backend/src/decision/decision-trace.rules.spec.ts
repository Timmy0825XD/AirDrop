import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import {
  NO_CORRIDOR_NOTE,
  NO_LOT_NOTE,
  EvaluationView,
  buildDecisionTrace,
  outcomeOf,
  presentDecision,
  traceEvaluatedHub,
} from './decision-trace.rules';
import { BATTERY_TOO_LOW, DRONE_MAINTENANCE } from './decision.rules';

const hub = { id: 'hub-1', name: 'Hospital Rosario' };
const drones = [
  { id: 'd1', identifier: 'WC-01', droneModelId: 'm' },
  { id: 'd2', identifier: 'WC-02', droneModelId: 'm' },
  { id: 'd3', identifier: 'WC-03', droneModelId: 'm' },
];

function evaluation(overrides: Partial<EvaluationView> = {}): EvaluationView {
  return {
    lot: { id: 'lot' },
    drones,
    modelsById: new Map([['m', { maxRangeKm: 110 }]]),
    corridor: { altitudeM: 100, distanceKm: 11, coordinates: [] },
    choice: {
      chosen: {
        droneId: 'd2',
        identifier: 'WC-02',
        distanceKm: 11,
        preemptsOrderId: null,
      },
      discarded: [
        { droneId: 'd1', identifier: 'WC-01', reason: DRONE_MAINTENANCE },
      ],
    },
    etaMs: 324_000,
    inRange: true,
    ...overrides,
  };
}

describe('traceEvaluatedHub', () => {
  it('dice qué dron se eligió, cuál se descartó y por qué, y cuál quedó elegible', () => {
    const trace = traceEvaluatedHub(hub, evaluation());
    expect(trace.drones).toEqual([
      {
        identifier: 'WC-01',
        status: 'discarded',
        reason: DRONE_MAINTENANCE,
        preempts: false,
      },
      { identifier: 'WC-02', status: 'chosen', reason: null, preempts: false },
      {
        identifier: 'WC-03',
        status: 'eligible',
        reason: null,
        preempts: false,
      },
    ]);
  });

  it('muestra corredor, minutos de vuelo y batería que pide la misión', () => {
    const trace = traceEvaluatedHub(hub, evaluation());
    expect(trace.corridorKm).toBe(11);
    expect(trace.etaMin).toBe(5.4);
    // 2 × (8 + 10) + 20 = 56 %
    expect(trace.batteryNeededPercent).toBe(56);
    expect(trace.inRange).toBe(true);
    expect(trace.note).toBeNull();
  });

  it('marca cuando el dron elegido le quita la reserva a un programado', () => {
    const trace = traceEvaluatedHub(
      hub,
      evaluation({
        choice: {
          chosen: {
            droneId: 'd1',
            identifier: 'WC-01',
            distanceKm: 11,
            preemptsOrderId: 'programado',
          },
          discarded: [],
        },
      }),
    );
    expect(trace.drones[0]).toMatchObject({ status: 'chosen', preempts: true });
  });

  it('explica una central sin lote o sin corredor', () => {
    expect(traceEvaluatedHub(hub, evaluation({ lot: null })).note).toBe(
      NO_LOT_NOTE,
    );
    expect(traceEvaluatedHub(hub, evaluation({ lot: null })).drones).toEqual(
      [],
    );
    const blocked = traceEvaluatedHub(
      hub,
      evaluation({
        corridor: null,
        etaMs: null,
        inRange: false,
        choice: {
          chosen: null,
          discarded: drones.map((d) => ({
            droneId: d.id,
            identifier: d.identifier,
            reason: BATTERY_TOO_LOW,
          })),
        },
      }),
    );
    expect(blocked.note).toBe(NO_CORRIDOR_NOTE);
    expect(blocked.batteryNeededPercent).toBeNull();
  });
});

describe('buildDecisionTrace', () => {
  const now = new Date('2026-11-02T15:00:00.000Z');

  it('una asignación no lleva motivo', () => {
    const trace = buildDecisionTrace(
      {
        status: OrderStatus.PENDING_LOAD,
        fallbackKind: null,
        fallbackReason: null,
        statusReason: null,
      },
      [],
      now,
    );
    expect(trace).toEqual({
      at: now.toISOString(),
      outcome: 'assigned',
      reason: null,
      hubs: [],
    });
  });

  it('una alternativa guarda el motivo que vio quien pidió', () => {
    const trace = buildDecisionTrace(
      {
        status: OrderStatus.REASSIGNED,
        fallbackKind: FallbackKind.HUB,
        fallbackReason: 'El pedido pasó a Clínica Norte.',
        statusReason: null,
      },
      [],
      now,
    );
    expect(trace.outcome).toBe('reassigned');
    expect(trace.reason).toBe('El pedido pasó a Clínica Norte.');
  });

  it('distingue cada resultado del motor', () => {
    const at = (status: OrderStatus, fallbackKind: FallbackKind | null) =>
      outcomeOf({ status, fallbackKind });
    expect(at(OrderStatus.RECEIVED, FallbackKind.RETRY)).toBe('retry');
    expect(at(OrderStatus.REASSIGNED, FallbackKind.CONVENTIONAL)).toBe(
      'conventional',
    );
    expect(at(OrderStatus.REJECTED, null)).toBe('rejected');
    expect(at(OrderStatus.EXPIRED, null)).toBe('expired');
  });
});

describe('presentDecision', () => {
  it('muestra la escalera de ofertas en minutos', () => {
    const view = presentDecision({
      id: 'o1',
      decisionTrace: null,
      dispatchOffers: [
        {
          hubId: 'A',
          name: 'Central A',
          etaMs: 360_000,
          ready: true,
          offeredAt: '2026-11-02T15:00:00.000Z',
          declinedAt: '2026-11-02T15:00:20.000Z',
          declineReason: 'Sin dron',
        },
      ],
    });
    expect(view.offers).toEqual([
      {
        hubId: 'A',
        name: 'Central A',
        etaMin: 6,
        ready: true,
        offeredAt: '2026-11-02T15:00:00.000Z',
        declinedAt: '2026-11-02T15:00:20.000Z',
        declineReason: 'Sin dron',
      },
    ]);
  });

  it('un pedido sin escalera devuelve offers null', () => {
    expect(
      presentDecision({ id: 'o1', decisionTrace: null, dispatchOffers: null })
        .offers,
    ).toBeNull();
  });
});
