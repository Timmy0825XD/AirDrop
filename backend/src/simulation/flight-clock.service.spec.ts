import { OrderStatus } from '../common/enums/order-status.enum';
import { FlightClockService } from './flight-clock.service';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const LANDED_AT = new Date('2026-10-19T15:00:00.000Z');

function build(affected: number) {
  const orders = { update: jest.fn().mockResolvedValue({ affected }) };
  const notifications = {
    statusChanged: jest.fn().mockResolvedValue(undefined),
  };
  const service = new FlightClockService(
    orders as never,
    {} as never,
    {} as never,
    {} as never,
    {} as never,
    notifications as never,
  );
  service['waiting'].set(ORDER_ID, LANDED_AT);
  return { service, orders, notifications };
}

describe('FlightClockService expireDeliveryWaits', () => {
  afterEach(() => {
    delete process.env.DELIVERY_WAIT_MS;
  });

  it('CH-07 pasa a returning y avisa cuando vence la espera', async () => {
    const { service, orders, notifications } = build(1);

    await service.expireDeliveryWaits(new Date('2026-10-19T15:05:00.000Z'));

    expect(orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID, status: OrderStatus.AWAITING_DELIVERY },
      { status: OrderStatus.RETURNING },
    );
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      ORDER_ID,
      OrderStatus.RETURNING,
    );
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });

  it('no hace nada mientras la espera sigue vigente', async () => {
    const { service, orders, notifications } = build(1);

    await service.expireDeliveryWaits(new Date('2026-10-19T15:04:59.000Z'));

    expect(orders.update).not.toHaveBeenCalled();
    expect(notifications.statusChanged).not.toHaveBeenCalled();
    expect(service['waiting'].has(ORDER_ID)).toBe(true);
  });

  it('respeta DELIVERY_WAIT_MS', async () => {
    process.env.DELIVERY_WAIT_MS = '10000';
    const { service, orders } = build(1);

    await service.expireDeliveryWaits(new Date('2026-10-19T15:00:10.000Z'));

    expect(orders.update).toHaveBeenCalled();
  });

  it('no avisa si el pedido ya se entregó entre tanto', async () => {
    const { service, notifications } = build(0);

    await service.expireDeliveryWaits(new Date('2026-10-19T15:05:00.000Z'));

    expect(notifications.statusChanged).not.toHaveBeenCalled();
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });
});
