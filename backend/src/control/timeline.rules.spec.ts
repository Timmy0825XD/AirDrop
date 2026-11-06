import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DecisionTrace } from '../orders/order.entity';
import {
  OrderFacts,
  TIMELINE_DEFAULT_LIMIT,
  TIMELINE_MAX,
  alertDraft,
  clampTimelineLimit,
  clockDraft,
  decisionSummary,
  missionLabel,
  queueDraft,
  rerouteDraft,
  statusDraft,
} from './timeline.rules';

const HUB = { id: 'hub-1', name: 'Hospital Rosario Pumarejo' };

function facts(overrides: Partial<OrderFacts> = {}): OrderFacts {
  return {
    id: 'order-1',
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    medicationName: 'Suero antiofídico',
    fallbackKind: null,
    originHub: HUB,
    destinationHubName: null,
    drone: { id: 'drone-1', identifier: 'WC-03' },
    decisionTrace: null,
    ...overrides,
  };
}

const trace: DecisionTrace = {
  at: '2026-11-05T15:00:00.000Z',
  outcome: 'assigned',
  reason: null,
  hubs: [
    {
      hubId: HUB.id,
      name: HUB.name,
      lot: true,
      corridorKm: 12,
      etaMin: 6,
      batteryNeededPercent: 40,
      inRange: true,
      note: null,
      drones: [
        {
          droneId: 'drone-1',
          identifier: 'WC-03',
          status: 'chosen',
          reason: null,
          preempts: false,
          batteryPercent: 90,
        },
        {
          droneId: 'drone-2',
          identifier: 'WC-01',
          status: 'discarded',
          reason: 'Batería insuficiente para ida, regreso y reserva.',
          preempts: false,
          batteryPercent: 30,
        },
        {
          droneId: 'drone-3',
          identifier: 'WC-02',
          status: 'eligible',
          reason: null,
          preempts: false,
          batteryPercent: 80,
        },
      ],
    },
  ],
} as unknown as DecisionTrace;

describe('línea de tiempo (RF-39)', () => {
  it('nombra los cuatro pedidos', () => {
    expect(missionLabel(MissionType.EMERGENCY, DestinationKind.PERSON)).toBe(
      'Urgencia a una persona',
    );
    expect(missionLabel(MissionType.EMERGENCY, DestinationKind.HUB)).toBe(
      'Urgencia entre centrales',
    );
    expect(missionLabel(MissionType.SCHEDULED, DestinationKind.PERSON)).toBe(
      'Entrega programada',
    );
    expect(missionLabel(MissionType.SCHEDULED, DestinationKind.HUB)).toBe(
      'Abastecimiento programado',
    );
  });

  it('nunca dice el medicamento de una entrega a una persona', () => {
    for (const status of [
      OrderStatus.RECEIVED,
      OrderStatus.PENDING_LOAD,
      OrderStatus.IN_FLIGHT,
      OrderStatus.DELIVERED,
    ]) {
      const draft = statusDraft(status, facts(), null);
      expect(JSON.stringify(draft)).not.toContain('Suero');
    }
  });

  it('en un traslado entre centrales sí dice el insumo y a qué central va', () => {
    const draft = statusDraft(
      OrderStatus.IN_FLIGHT,
      facts({
        destinationKind: DestinationKind.HUB,
        destinationHubName: 'Banco de sangre',
      }),
      { latitude: 10.46, longitude: -73.25 },
    );
    expect(draft).toMatchObject({
      kind: 'flight',
      title: 'Carga confirmada: despegó WC-03',
      detail: `Desde ${HUB.name}, Suero antiofídico hacia Banco de sangre`,
      latitude: 10.46,
      longitude: -73.25,
    });
  });

  it('explica la decisión: el elegido, los que podían y los descartados con su motivo', () => {
    expect(decisionSummary(trace)).toBe(
      'Eligió WC-03. 1 dron más podía salir. Descartó WC-01 (batería insuficiente para ida, regreso y reserva).',
    );
    const draft = statusDraft(
      OrderStatus.PENDING_LOAD,
      facts({ decisionTrace: trace }),
      null,
    );
    expect(draft?.title).toBe(`${HUB.name} autorizó: sale WC-03`);
  });

  it('dice cuando la urgencia le quita el dron a un programado', () => {
    const preempting = structuredClone(trace);
    preempting.hubs[0].drones[0].preempts = true;
    expect(decisionSummary(preempting)).toContain('la urgencia gana el dron');
  });

  it('distingue la reasignación del traslado convencional', () => {
    expect(
      statusDraft(
        OrderStatus.REASSIGNED,
        facts({ fallbackKind: FallbackKind.CONVENTIONAL }),
        null,
      )?.title,
    ).toBe('Urgencia a una persona: traslado convencional');
    expect(
      statusDraft(
        OrderStatus.REASSIGNED,
        facts({ fallbackKind: FallbackKind.HUB }),
        null,
      )?.title,
    ).toBe(`Urgencia a una persona reasignada a ${HUB.name}`);
  });

  it('el rechazo no muestra el motivo: puede hablar de la fórmula', () => {
    const draft = statusDraft(OrderStatus.REJECTED, facts(), null);
    expect(draft?.severity).toBe('danger');
    expect(draft?.detail).toBeNull();
  });

  it('no cuenta los estados que no son del flujo en vivo', () => {
    expect(statusDraft(OrderStatus.SCHEDULED, facts(), null)).toBeNull();
    expect(statusDraft(OrderStatus.CANCELLED, facts(), null)).toBeNull();
  });

  it('cuenta la cola, la alerta y el reloj', () => {
    expect(queueDraft(facts(), HUB, null).title).toBe(
      `Urgencia a una persona en la cola de ${HUB.name}`,
    );
    expect(
      alertDraft(
        'cold_chain',
        'La temperatura salió del rango.',
        { id: 'order-1', hubId: HUB.id },
        { id: 'drone-1', identifier: 'WC-03' },
        null,
      ),
    ).toMatchObject({
      kind: 'alert',
      severity: 'danger',
      title: 'Carga fuera de 2 a 8 °C en WC-03',
    });
    expect(clockDraft({ now: '', speed: 4, paused: false }).title).toBe(
      'Reloj a x4',
    );
    expect(clockDraft({ now: '', speed: 4, paused: true })).toMatchObject({
      title: 'Reloj en pausa',
      source: 'console',
    });
  });

  it('cuenta el cambio de ruta con lo que suma el desvío (RF-33)', () => {
    const draft = rerouteDraft(
      facts(),
      {
        outcome: 'rerouted',
        addedKm: 1.4,
        crossesGeofence: false,
        batteryShort: false,
      },
      null,
    );
    expect(draft).toMatchObject({
      kind: 'flight',
      severity: 'warning',
      title: 'WC-03 cambió de ruta',
      detail: 'Una zona nueva cruzaba su camino: el desvío suma 1,4 km.',
    });
  });

  it('marca en rojo un desvío que cruza la zona o que deja corta la batería', () => {
    const draft = rerouteDraft(
      facts(),
      {
        outcome: 'rerouted',
        addedKm: 2,
        crossesGeofence: true,
        batteryShort: true,
      },
      null,
    );
    expect(draft.severity).toBe('danger');
    expect(draft.detail).toContain('Tuvo que cruzar la zona');
    expect(draft.detail).toContain('la batería no alcanza');
  });

  it('sin camino seguro lo dice claro', () => {
    expect(
      rerouteDraft(
        facts(),
        {
          outcome: 'blocked',
          addedKm: null,
          crossesGeofence: true,
          batteryShort: false,
        },
        null,
      ),
    ).toMatchObject({
      severity: 'danger',
      title: 'WC-03 no tiene una ruta segura',
    });
  });

  it('el límite de la consulta cae entre 1 y el tope', () => {
    expect(clampTimelineLimit(undefined)).toBe(TIMELINE_DEFAULT_LIMIT);
    expect(clampTimelineLimit('abc')).toBe(TIMELINE_DEFAULT_LIMIT);
    expect(clampTimelineLimit('0')).toBe(TIMELINE_DEFAULT_LIMIT);
    expect(clampTimelineLimit('10')).toBe(10);
    expect(clampTimelineLimit('5000')).toBe(TIMELINE_MAX);
  });
});
