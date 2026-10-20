import { BadRequestException, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { hashOtp } from '../auth/auth.rules';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Drone } from '../fleet/drone.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { User } from '../users/user.entity';
import { DeliveryCode } from './delivery-code.entity';
import { DeliveryService } from './delivery.service';
import {
  DELIVERY_CODE_REJECTED,
  DELIVERY_WAIT_EXPIRED,
  DEFAULT_DELIVERY_WAIT_MS,
  ONLY_AWAITING_DELIVERY_IS_DELIVERED,
  ORDER_ALREADY_DELIVERED,
  deliveryWaitMs,
} from './delivery.rules';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const REQUESTER_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const CODE = '123456';

const requester = { id: REQUESTER_ID } as User;

function order(overrides: Partial<Order> = {}): Order {
  return {
    id: ORDER_ID,
    requesterId: REQUESTER_ID,
    droneId: DRONE_ID,
    status: OrderStatus.AWAITING_DELIVERY,
    ...overrides,
  } as Order;
}

function storedCode(overrides: Partial<DeliveryCode> = {}): DeliveryCode {
  return {
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    orderId: ORDER_ID,
    codeHash: hashOtp(CODE),
    expiresAt: new Date(Date.now() + 60_000),
    usedAt: null,
    ...overrides,
  };
}

describe('DeliveryService', () => {
  let current: Order | null;
  let mission: Mission | null;
  let code: DeliveryCode | null;
  let manager: {
    findOne: jest.Mock;
    create: jest.Mock;
    save: jest.Mock;
    update: jest.Mock;
  };
  let notifications: { statusChanged: jest.Mock };
  let service: DeliveryService;

  beforeEach(() => {
    current = order();
    mission = { orderId: ORDER_ID, landedAt: new Date() } as Mission;
    code = null;
    manager = {
      findOne: jest.fn((entity: unknown) => {
        if (entity === Order) return Promise.resolve(current);
        if (entity === Mission) return Promise.resolve(mission);
        if (entity === DeliveryCode) return Promise.resolve(code);
        return Promise.resolve(null);
      }),
      create: jest.fn((_entity: unknown, data: object) => ({ ...data })),
      save: jest.fn((entity: unknown) => Promise.resolve(entity)),
      update: jest.fn().mockResolvedValue(undefined),
    };
    const dataSource = {
      transaction: jest.fn((work: (m: unknown) => Promise<unknown>) =>
        work(manager),
      ),
    } as unknown as DataSource;
    notifications = { statusChanged: jest.fn().mockResolvedValue(undefined) };
    service = new DeliveryService(
      dataSource,
      notifications as unknown as NotificationsService,
    );
  });

  afterEach(() => {
    delete process.env.DELIVERY_WAIT_MS;
  });

  describe('generate', () => {
    it('devuelve un código de 6 dígitos y guarda solo su hash', async () => {
      const result = await service.generate(requester, ORDER_ID);

      expect(result.code).toMatch(/^\d{6}$/);
      const [saved] = manager.save.mock.calls[0] as [DeliveryCode];
      expect(saved.codeHash).toBe(hashOtp(result.code));
      expect(saved.codeHash).not.toContain(result.code);
      expect(result.expiresAt.getTime()).toBe(
        mission!.landedAt!.getTime() + DEFAULT_DELIVERY_WAIT_MS,
      );
    });

    it('usa DELIVERY_WAIT_MS cuando está configurado', () => {
      process.env.DELIVERY_WAIT_MS = '10000';
      expect(deliveryWaitMs()).toBe(10_000);
      process.env.DELIVERY_WAIT_MS = 'abc';
      expect(deliveryWaitMs()).toBe(DEFAULT_DELIVERY_WAIT_MS);
    });

    it('responde 404 si el pedido es de otro solicitante', async () => {
      current = order({ requesterId: 'otro' });
      await expect(service.generate(requester, ORDER_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('rechaza un pedido que no está en espera de entrega', async () => {
      current = order({ status: OrderStatus.IN_FLIGHT });
      await expect(service.generate(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED),
      );
    });

    it('avisa que el pedido ya fue entregado', async () => {
      current = order({ status: OrderStatus.DELIVERED });
      await expect(service.generate(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(ORDER_ALREADY_DELIVERED),
      );
    });

    it('rechaza si el tiempo de espera ya venció', async () => {
      mission = {
        orderId: ORDER_ID,
        landedAt: new Date(Date.now() - DEFAULT_DELIVERY_WAIT_MS - 1000),
      } as Mission;
      await expect(service.generate(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(DELIVERY_WAIT_EXPIRED),
      );
    });
  });

  describe('validate', () => {
    it('entrega el pedido, usa el código, libera el dron y avisa', async () => {
      code = storedCode();

      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
      expect(code.usedAt).toBeInstanceOf(Date);
      expect(manager.update).toHaveBeenCalledWith(
        Drone,
        { id: DRONE_ID },
        { status: DroneStatus.AVAILABLE },
      );
      expect(notifications.statusChanged).toHaveBeenCalledWith(
        ORDER_ID,
        OrderStatus.DELIVERED,
      );
    });

    it('rechaza un código incorrecto sin cambiar nada', async () => {
      code = storedCode();

      await expect(
        service.validate(requester, ORDER_ID, '000000'),
      ).rejects.toThrow(new BadRequestException(DELIVERY_CODE_REJECTED));

      expect(code.usedAt).toBeNull();
      expect(current!.status).toBe(OrderStatus.AWAITING_DELIVERY);
      expect(manager.update).not.toHaveBeenCalled();
      expect(notifications.statusChanged).not.toHaveBeenCalled();
    });

    it('rechaza un código vencido', async () => {
      code = storedCode({ expiresAt: new Date(Date.now() - 1000) });
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );
    });

    it('rechaza un código ya usado', async () => {
      code = storedCode({ usedAt: new Date() });
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );
    });

    it('rechaza si nunca se generó un código', async () => {
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );
    });

    it('rechaza un segundo intento cuando el pedido ya está entregado', async () => {
      current = order({ status: OrderStatus.DELIVERED });
      code = storedCode({ usedAt: new Date() });
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );
    });

    it('rechaza un pedido que no está en espera de entrega', async () => {
      current = order({ status: OrderStatus.RETURNING });
      code = storedCode();
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED),
      );
    });

    it('responde 404 si el pedido es de otro solicitante', async () => {
      current = order({ requesterId: 'otro' });
      code = storedCode();
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
