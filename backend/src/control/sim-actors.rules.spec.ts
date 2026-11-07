import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DispatchOffer } from '../orders/order.entity';
import {
  ACTORS_OFF,
  AUTHORIZE_DELAY_MS,
  RECEIVER_MAX_DELAY_MS,
  RECEIVER_MIN_DELAY_MS,
  actorsChangeText,
  applyActorsChange,
  awaitsAutoAuthorization,
  flowKind,
  isDue,
  nextScheduledSlot,
  parseActorsState,
  pickAuthorizingHub,
  receiverCodeAt,
  scatterAround,
  turnStartedAt,
} from './sim-actors.rules';

/** Un `Math.random` que devuelve, en orden, los números dados. */
function sequence(...values: number[]): () => number {
  let index = 0;
  return () => values[Math.min(index++, values.length - 1)];
}

function offer(hubId: string, offeredAt: string | null): DispatchOffer {
  return {
    hubId,
    name: hubId,
    etaMs: 60_000,
    ready: true,
    offeredAt,
    declinedAt: null,
    declineReason: null,
  };
}

const CREATED = new Date('2026-11-06T15:00:00.000Z');

function turnOrder(
  overrides: Partial<Parameters<typeof turnStartedAt>[0]> = {},
) {
  return {
    missionType: MissionType.EMERGENCY,
    createdAt: CREATED,
    reassignedAt: null,
    dispatchOffers: null,
    scheduledAt: null,
    windowEndsAt: null,
    scheduledFor: null,
    fallbackKind: null,
    reassignedFromHubId: null,
    ...overrides,
  };
}

describe('sim-actors.rules (RF-37)', () => {
  describe('interruptores', () => {
    it('arrancan apagados y un estado roto en Redis también los apaga', () => {
      expect(parseActorsState(null)).toEqual(ACTORS_OFF);
      expect(parseActorsState('{roto')).toEqual(ACTORS_OFF);
      expect(parseActorsState('{"autoDispatcher":true}')).toEqual({
        autoDispatcher: true,
        orderFlow: false,
      });
    });

    it('lo que no llega se queda como estaba, y se cuenta solo lo que cambió', () => {
      const before = { autoDispatcher: true, orderFlow: false };
      const after = applyActorsChange(before, { orderFlow: true });
      expect(after).toEqual({ autoDispatcher: true, orderFlow: true });
      expect(actorsChangeText(before, after)).toEqual([
        'Flujo continuo de pedidos encendido',
      ]);
    });
  });

  describe('despachador automático', () => {
    it('autoriza lo que espera central, no lo que ya tiene dron ni el programado que espera dron', () => {
      const base = {
        status: OrderStatus.RECEIVED,
        fallbackKind: null,
        droneId: null,
      };
      expect(awaitsAutoAuthorization(base)).toBe(true);
      expect(awaitsAutoAuthorization({ ...base, droneId: 'd1' })).toBe(false);
      expect(
        awaitsAutoAuthorization({ ...base, fallbackKind: FallbackKind.RETRY }),
      ).toBe(false);
      expect(
        awaitsAutoAuthorization({
          ...base,
          status: OrderStatus.REASSIGNED,
          fallbackKind: FallbackKind.HUB,
        }),
      ).toBe(true);
      expect(
        awaitsAutoAuthorization({ ...base, status: OrderStatus.PENDING_LOAD }),
      ).toBe(false);
    });

    it('a la urgencia escalonada le toca desde que se le ofreció a esa central', () => {
      const order = turnOrder({
        dispatchOffers: [
          offer('h1', '2026-11-06T15:00:05.000Z'),
          offer('h2', '2026-11-06T15:02:00.000Z'),
        ],
      });
      expect(turnStartedAt(order, 'h2').toISOString()).toBe(
        '2026-11-06T15:02:00.000Z',
      );
    });

    it('al programado le toca cuando abre su ventana, 2 h antes de la franja', () => {
      const order = turnOrder({
        missionType: MissionType.SCHEDULED,
        scheduledAt: new Date('2026-11-06T20:00:00.000Z'),
        windowEndsAt: new Date('2026-11-06T21:00:00.000Z'),
        scheduledFor: '2026-11-06',
      });
      expect(turnStartedAt(order, 'h1').toISOString()).toBe(
        '2026-11-06T18:00:00.000Z',
      );
    });

    it('espera 10 s simulados antes de autorizar', () => {
      expect(
        isDue(CREATED, AUTHORIZE_DELAY_MS, new Date(CREATED.getTime() + 9_999)),
      ).toBe(false);
      expect(
        isDue(
          CREATED,
          AUTHORIZE_DELAY_MS,
          new Date(CREATED.getTime() + 10_000),
        ),
      ).toBe(true);
    });

    it('elige la central a la que se le ofreció primero; si no hay oferta, la más cercana', () => {
      const hubs = [
        { id: 'lejos', latitude: 10.5, longitude: -73.3 },
        { id: 'cerca', latitude: 10.47, longitude: -73.25 },
      ];
      const destination = { latitude: 10.471, longitude: -73.251 };
      expect(
        pickAuthorizingHub({ ...destination, dispatchOffers: null }, hubs),
      ).toBe('cerca');
      expect(
        pickAuthorizingHub(
          {
            ...destination,
            dispatchOffers: [
              offer('cerca', '2026-11-06T15:05:00.000Z'),
              offer('lejos', '2026-11-06T15:00:00.000Z'),
            ],
          },
          hubs,
        ),
      ).toBe('lejos');
      expect(
        pickAuthorizingHub({ ...destination, dispatchOffers: null }, []),
      ).toBeNull();
    });
  });

  describe('receptor simulado', () => {
    const landed = new Date('2026-11-06T15:10:00.000Z');

    it('en el 85 % ingresa el código entre 20 s y 2 min después del aterrizaje', () => {
      const early = receiverCodeAt(landed, sequence(0.1, 0));
      const late = receiverCodeAt(landed, sequence(0.84, 0.999999));
      expect(early?.getTime()).toBe(landed.getTime() + RECEIVER_MIN_DELAY_MS);
      expect(late?.getTime()).toBeLessThanOrEqual(
        landed.getTime() + RECEIVER_MAX_DELAY_MS,
      );
      expect(late?.getTime()).toBeGreaterThan(
        landed.getTime() + RECEIVER_MIN_DELAY_MS,
      );
    });

    it('en el otro 15 % deja vencer los 5 minutos (RF-30)', () => {
      expect(receiverCodeAt(landed, sequence(0.85))).toBeNull();
      expect(receiverCodeAt(landed, sequence(0.99))).toBeNull();
    });
  });

  describe('generador', () => {
    it('el flujo saca 70 % urgencias', () => {
      expect(flowKind(() => 0.69)).toBe('emergency');
      expect(flowKind(() => 0.7)).toBe('scheduled');
    });

    it('el programado va a la primera franja en punto que empieza en más de 2 horas', () => {
      // 10:20 en Colombia → 12:20 es el mínimo → la franja de las 13:00.
      expect(nextScheduledSlot(new Date('2026-11-06T15:20:00.000Z'))).toEqual({
        date: '2026-11-06',
        time: '13:00',
      });
    });

    it('después de las 15:00 pasa a las 7:00 del día siguiente', () => {
      // 16:30 en Colombia: la de las 17:00 ya no alcanza.
      expect(nextScheduledSlot(new Date('2026-11-06T21:30:00.000Z'))).toEqual({
        date: '2026-11-07',
        time: '07:00',
      });
    });

    it('reparte el pico dentro del radio, con 6 decimales', () => {
      const center = { latitude: 10.47, longitude: -73.25 };
      const random = sequence(0.99, 0.25, 0.5, 0.75, 0.3, 0.1);
      for (let index = 0; index < 3; index += 1) {
        const point = scatterAround(center, 1, random);
        const km = Math.hypot(
          (point.latitude - center.latitude) * 111.32,
          (point.longitude - center.longitude) *
            111.32 *
            Math.cos((center.latitude * Math.PI) / 180),
        );
        expect(km).toBeLessThanOrEqual(1.001);
        expect(Number(point.latitude.toFixed(6))).toBe(point.latitude);
      }
    });
  });
});
