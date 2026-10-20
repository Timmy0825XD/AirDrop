import { BadRequestException, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { hashOtp } from '../auth/auth.rules';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { FlightClockService } from '../simulation/flight-clock.service';
import { Mission } from '../simulation/mission.entity';
import { User } from '../users/user.entity';
import { DeliveryCode } from './delivery-code.entity';
import { DeliveryService } from './delivery.service';
import {
  DELIVERY_CODE_LOCKED,
  DELIVERY_CODE_MAX_ATTEMPTS,
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

const HUB_ID = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

const requester = { id: REQUESTER_ID, role: UserRole.REQUESTER } as User;

function dispatcherOf(hubId: string): User {
  return {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    role: UserRole.DISPATCHER,
    hubAssignments: [{ hubId }],
  } as unknown as User;
}

function order(overrides: Partial<Order> = {}): Order {
  return {
    id: ORDER_ID,
    requesterId: REQUESTER_ID,
    destinationKind: DestinationKind.PERSON,
    destinationHubId: null,
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
    attempts: 0,
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
  let flights: { startReturn: jest.Mock };
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
    flights = { startReturn: jest.fn().mockResolvedValue(undefined) };
    service = new DeliveryService(
      dataSource,
      notifications as unknown as NotificationsService,
      flights as unknown as FlightClockService,
    );
  });

  afterEach(() => {
    delete process.env.DELIVERY_WAIT_MS;
  });

  describe('generate', () => {
    it('pedir un código nuevo no reinicia los intentos', async () => {
      code = storedCode({ attempts: 3 });

      await service.generate(requester, ORDER_ID);

      expect(code.attempts).toBe(3);
    });

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
    it('entrega el pedido, usa el código, avisa y manda al dron de vuelta', async () => {
      code = storedCode();

      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
      expect(code.usedAt).toBeInstanceOf(Date);
      expect(manager.update).not.toHaveBeenCalled();
      expect(flights.startReturn).toHaveBeenCalledWith(ORDER_ID);
      expect(notifications.statusChanged).toHaveBeenCalledWith(
        ORDER_ID,
        OrderStatus.DELIVERED,
      );
    });

    it('la entrega sigue valiendo aunque no arranque el regreso', async () => {
      code = storedCode();
      flights.startReturn.mockRejectedValueOnce(new Error('sin Redis'));

      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
    });

    it('rechaza un código incorrecto sin cambiar nada', async () => {
      code = storedCode();

      await expect(
        service.validate(requester, ORDER_ID, '000000'),
      ).rejects.toThrow(new BadRequestException(DELIVERY_CODE_REJECTED));

      expect(code.usedAt).toBeNull();
      expect(current!.status).toBe(OrderStatus.AWAITING_DELIVERY);
      expect(flights.startReturn).not.toHaveBeenCalled();
      expect(notifications.statusChanged).not.toHaveBeenCalled();
    });

    it('cuenta cada código equivocado y lo guarda', async () => {
      code = storedCode();

      await expect(
        service.validate(requester, ORDER_ID, '000000'),
      ).rejects.toThrow(DELIVERY_CODE_REJECTED);

      expect(code.attempts).toBe(1);
      expect(manager.save).toHaveBeenCalledWith(code);
    });

    it('bloquea el pedido al agotar los intentos', async () => {
      code = storedCode({ attempts: DELIVERY_CODE_MAX_ATTEMPTS - 1 });

      await expect(
        service.validate(requester, ORDER_ID, '000000'),
      ).rejects.toThrow(new BadRequestException(DELIVERY_CODE_LOCKED));

      expect(code.attempts).toBe(DELIVERY_CODE_MAX_ATTEMPTS);
    });

    it('con el pedido bloqueado ni el código correcto entrega', async () => {
      code = storedCode({ attempts: DELIVERY_CODE_MAX_ATTEMPTS });

      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_LOCKED),
      );

      expect(code.usedAt).toBeNull();
      expect(current!.status).toBe(OrderStatus.AWAITING_DELIVERY);
      expect(flights.startReturn).not.toHaveBeenCalled();
    });

    it('el código correcto entrega aunque haya intentos fallidos previos', async () => {
      code = storedCode({ attempts: DELIVERY_CODE_MAX_ATTEMPTS - 1 });

      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
    });

    it('un código vencido o ya usado no cuenta como intento', async () => {
      code = storedCode({ expiresAt: new Date(Date.now() - 1000) });

      await expect(
        service.validate(requester, ORDER_ID, '000000'),
      ).rejects.toThrow(DELIVERY_CODE_REJECTED);

      expect(code.attempts).toBe(0);
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

  describe('entrega a una central', () => {
    const hubOrder = () =>
      order({
        requesterId: null,
        destinationKind: DestinationKind.HUB,
        destinationHubId: HUB_ID,
      });

    it('el despachador de la central de destino genera y valida el código', async () => {
      current = hubOrder();
      const dispatcher = dispatcherOf(HUB_ID);

      const generated = await service.generate(dispatcher, ORDER_ID);
      code = storedCode({ codeHash: hashOtp(generated.code) });
      const result = await service.validate(
        dispatcher,
        ORDER_ID,
        generated.code,
      );

      expect(result.status).toBe(OrderStatus.DELIVERED);
    });

    it('un despachador de otra central recibe 404', async () => {
      current = hubOrder();
      await expect(
        service.generate(dispatcherOf('otra-central'), ORDER_ID),
      ).rejects.toThrow(NotFoundException);
    });

    it('el solicitante no entrega un pedido cuyo destino es una central', async () => {
      current = hubOrder();
      await expect(service.generate(requester, ORDER_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('un despachador no entrega un pedido cuyo destino es una persona', async () => {
      await expect(
        service.generate(dispatcherOf(HUB_ID), ORDER_ID),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
