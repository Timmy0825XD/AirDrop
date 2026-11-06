import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { IncidentRedispatchService } from './incident-redispatch.service';
import {
  REDISPATCH_REASON,
  canRedispatch,
  redispatchPath,
  releaseForRedispatch,
} from './redispatch.rules';

function failed(overrides: Partial<Order> = {}): Order {
  return {
    id: 'order-1',
    status: OrderStatus.IN_FLIGHT,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    droneId: 'drone-1',
    inventoryItemId: 'lot-1',
    originHubId: 'hub-1',
    authorizedAt: new Date('2026-11-06T14:00:00.000Z'),
    loadConfirmedAt: new Date('2026-11-06T14:01:00.000Z'),
    dispatchedLot: 'L-0001',
    dispatchedLotExpiresOn: '2027-01-01',
    coldChainAlertAt: null,
    returnCheckedAt: null,
    returnOutcome: null,
    dispatchOffers: [],
    nextEscalationAt: null,
    fallbackKind: FallbackKind.HUB,
    fallbackReason: 'x',
    fallbackOptions: null,
    retryAfter: null,
    statusReason: null,
    ...overrides,
  } as Order;
}

describe('Volver a despachar tras un incidente (RF-35, CU-44)', () => {
  it('solo la misión que se cayó en vuelo o que volvió a la central', () => {
    expect(canRedispatch(failed())).toBe(true);
    expect(canRedispatch(failed({ status: OrderStatus.RETURNED }))).toBe(true);
    expect(canRedispatch(failed({ status: OrderStatus.DELIVERED }))).toBe(
      false,
    );
    expect(canRedispatch(failed({ droneId: null }))).toBe(false);
  });

  it('la urgencia a una persona se ofrece otra vez; entre centrales, a su central; el programado, RF-18', () => {
    expect(redispatchPath(failed())).toBe('offers');
    expect(
      redispatchPath(failed({ destinationKind: DestinationKind.HUB })),
    ).toBe('same_hub');
    expect(redispatchPath(failed({ missionType: MissionType.SCHEDULED }))).toBe(
      'scheduled',
    );
  });

  it('suelta dron, lote y carga: hay que confirmar la carga otra vez', () => {
    const order = failed();
    releaseForRedispatch(order, 'offers');
    expect(order).toMatchObject({
      status: OrderStatus.RECEIVED,
      statusReason: REDISPATCH_REASON,
      droneId: null,
      inventoryItemId: null,
      loadConfirmedAt: null,
      dispatchedLot: null,
      // RU-10 recalcula a quién se ofrece, sin central fija.
      originHubId: null,
      dispatchOffers: null,
      fallbackKind: null,
    });
  });

  it('la urgencia entre centrales conserva su central de origen', () => {
    const order = failed({ destinationKind: DestinationKind.HUB });
    releaseForRedispatch(order, 'same_hub');
    expect(order.originHubId).toBe('hub-1');
    expect(order.status).toBe(OrderStatus.RECEIVED);
  });

  it('el aviso del reloj abre la oferta de la urgencia a una persona', async () => {
    let listener: ((id: string) => Promise<void>) | null = null;
    const flights = {
      onMissionAborted: (fn: (id: string) => Promise<void>) => {
        listener = fn;
      },
    };
    const decision = {
      redispatchAfterIncident: jest
        .fn()
        .mockResolvedValueOnce('offers')
        .mockResolvedValueOnce('scheduled'),
    };
    const dispatch = { start: jest.fn().mockResolvedValue(undefined) };
    new IncidentRedispatchService(
      flights as never,
      decision as never,
      dispatch as never,
    ).onModuleInit();
    await listener!('order-1');
    expect(dispatch.start).toHaveBeenCalledWith('order-1');
    await listener!('order-2');
    expect(dispatch.start).toHaveBeenCalledTimes(1);
  });
});
