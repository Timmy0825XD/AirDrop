import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { SimulatedReceiverService } from './simulated-receiver.service';
import { RECEIVER_MIN_DELAY_MS } from './sim-actors.rules';

const LANDED = new Date('2026-11-06T15:10:00.000Z');
const REQUESTER = { id: 'sim-1', simulated: true };

function build(random: () => number) {
  const waiting: Order[] = [
    {
      id: 'order-1',
      status: OrderStatus.AWAITING_DELIVERY,
      requesterId: REQUESTER.id,
    } as Order,
  ];
  const builder = {
    innerJoin: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getMany: jest.fn(() => Promise.resolve(waiting)),
  };
  const orders = { createQueryBuilder: jest.fn(() => builder) };
  const missions = {
    findOne: jest.fn().mockResolvedValue({ landedAt: LANDED }),
  };
  const users = { findOne: jest.fn().mockResolvedValue(REQUESTER) };
  const delivery = {
    show: jest.fn().mockResolvedValue({ code: '123456', expiresAt: null }),
    validate: jest.fn().mockResolvedValue({}),
  };
  const service = new SimulatedReceiverService(
    { get: () => 'true' } as never,
    delivery as never,
    orders as never,
    missions as never,
    users as never,
  );
  service.random = random;
  return { service, delivery, builder };
}

describe('SimulatedReceiverService (RF-37)', () => {
  it('solo mira los pedidos de solicitantes simulados que esperan el código', async () => {
    const { service, builder } = build(() => 0);
    await service.runDue(LANDED);
    expect(builder.where).toHaveBeenCalledWith('o.status = :status', {
      status: OrderStatus.AWAITING_DELIVERY,
    });
    expect(builder.andWhere).toHaveBeenCalledWith('requester.simulated = true');
  });

  it('a tiempo: lee el código y lo ingresa con el mismo servicio de la app', async () => {
    const { service, delivery } = build(() => 0);
    await service.runDue(LANDED);
    expect(delivery.validate).not.toHaveBeenCalled();
    await service.runDue(new Date(LANDED.getTime() + RECEIVER_MIN_DELAY_MS));
    expect(delivery.show).toHaveBeenCalledWith(REQUESTER, 'order-1');
    expect(delivery.validate).toHaveBeenCalledWith(REQUESTER, 'order-1', {
      code: '123456',
    });
  });

  it('cuando le toca no llegar, deja vencer los 5 minutos sin ingresar nada', async () => {
    const { service, delivery } = build(() => 0.9);
    await service.runDue(LANDED);
    await service.runDue(new Date(LANDED.getTime() + 5 * 60_000));
    expect(delivery.show).not.toHaveBeenCalled();
    expect(delivery.validate).not.toHaveBeenCalled();
  });

  it('lo intenta una sola vez aunque el servicio lo rechace', async () => {
    const { service, delivery } = build(() => 0);
    delivery.validate.mockRejectedValue(new Error('Código vencido.'));
    const later = new Date(LANDED.getTime() + RECEIVER_MIN_DELAY_MS);
    await service.runDue(later);
    await service.runDue(new Date(later.getTime() + 5_000));
    expect(delivery.validate).toHaveBeenCalledTimes(1);
  });
});
