import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
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
  DEFAULT_DELIVERY_WAIT_MS,
  DELIVERY_CODE_LOCKED,
  DELIVERY_CODE_MAX_ATTEMPTS,
  DELIVERY_CODE_NOT_AVAILABLE,
  DELIVERY_CODE_NOT_READY,
  DELIVERY_CODE_REJECTED,
  DELIVERY_WAIT_EXPIRED,
  ONLY_AWAITING_DELIVERY_IS_DELIVERED,
  ORDER_ALREADY_DELIVERED,
  deliveryCodeFor,
} from './delivery.rules';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const REQUESTER_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_ID = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const SECRET = 'secreto-de-prueba';
const LOADED_AT = new Date('2026-10-19T14:00:00.000Z');
const CODE = deliveryCodeFor(
  { id: ORDER_ID, loadConfirmedAt: LOADED_AT },
  SECRET,
);
const WRONG = CODE === '000000' ? '111111' : '000000';

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
    loadConfirmedAt: LOADED_AT,
    status: OrderStatus.AWAITING_DELIVERY,
    ...overrides,
  } as Order;
}

function state(overrides: Partial<DeliveryCode> = {}): DeliveryCode {
  return {
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    orderId: ORDER_ID,
    usedAt: null,
    attempts: 0,
    ...overrides,
  };
}

describe('DeliveryService', () => {
  let current: Order | null;
  let mission: Mission | null;
  let stored: DeliveryCode | null;
  let manager: {
    findOne: jest.Mock;
    create: jest.Mock;
    save: jest.Mock;
  };
  let notifications: { statusChanged: jest.Mock };
  let flights: { startReturn: jest.Mock };
  let service: DeliveryService;

  beforeEach(() => {
    current = order();
    mission = { orderId: ORDER_ID, landedAt: new Date() } as Mission;
    stored = null;
    manager = {
      findOne: jest.fn((entity: unknown) => {
        if (entity === Order) return Promise.resolve(current);
        if (entity === Mission) return Promise.resolve(mission);
        if (entity === DeliveryCode) return Promise.resolve(stored);
        return Promise.resolve(null);
      }),
      create: jest.fn((_entity: unknown, data: object) => ({
        ...data,
      })),
      save: jest.fn((entity: unknown) => Promise.resolve(entity)),
    };
    const dataSource = {
      manager,
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
      { getOrThrow: () => SECRET } as unknown as ConfigService,
    );
  });

  afterEach(() => {
    delete process.env.DELIVERY_WAIT_MS;
  });

  describe('show', () => {
    it('muestra el código ya con el dron en vuelo, sin hora límite', async () => {
      current = order({ status: OrderStatus.IN_FLIGHT });

      const result = await service.show(requester, ORDER_ID);

      expect(result).toEqual({ code: CODE, expiresAt: null });
    });

    it('con la carga confirmada y el dron aún en tierra también lo muestra', async () => {
      current = order({ status: OrderStatus.PENDING_LOAD });

      const result = await service.show(requester, ORDER_ID);

      expect(result.code).toBe(CODE);
    });

    it('es el mismo código cada vez que se pide', async () => {
      const first = await service.show(requester, ORDER_ID);
      const second = await service.show(requester, ORDER_ID);

      expect(second.code).toBe(first.code);
      expect(first.code).toMatch(/^\d{6}$/);
    });

    it('tras aterrizar indica hasta cuándo puede ingresarlo', async () => {
      const result = await service.show(requester, ORDER_ID);

      expect(result.expiresAt?.getTime()).toBe(
        mission!.landedAt!.getTime() + DEFAULT_DELIVERY_WAIT_MS,
      );
    });

    it('no guarda nada al mostrarlo', async () => {
      await service.show(requester, ORDER_ID);

      expect(manager.save).not.toHaveBeenCalled();
    });

    it('antes de confirmar la carga todavía no hay código', async () => {
      current = order({
        status: OrderStatus.PENDING_LOAD,
        loadConfirmedAt: null,
      });
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_NOT_READY),
      );

      current = order({ status: OrderStatus.RECEIVED, loadConfirmedAt: null });
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_NOT_READY),
      );
    });

    it('en retorno ya no hay código vigente', async () => {
      current = order({ status: OrderStatus.RETURNING });
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_NOT_AVAILABLE),
      );
    });

    it('avisa que el pedido ya fue entregado', async () => {
      current = order({ status: OrderStatus.DELIVERED });
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(ORDER_ALREADY_DELIVERED),
      );
    });

    it('vencida la espera ya no muestra el código', async () => {
      mission = {
        orderId: ORDER_ID,
        landedAt: new Date(Date.now() - DEFAULT_DELIVERY_WAIT_MS - 1000),
      } as Mission;
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        new BadRequestException(DELIVERY_WAIT_EXPIRED),
      );
    });

    it('responde 404 si el pedido es de otro solicitante', async () => {
      current = order({ requesterId: 'otro' });
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('quien despacha desde la central de origen no ve el código', async () => {
      await expect(
        service.show(dispatcherOf(HUB_ID), ORDER_ID),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('validate', () => {
    it('con el código correcto entrega el pedido, avisa y manda al dron de vuelta', async () => {
      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
      const [saved] = manager.save.mock.calls[0] as [DeliveryCode];
      expect(saved.usedAt).toBeInstanceOf(Date);
      expect(flights.startReturn).toHaveBeenCalledWith(ORDER_ID);
      expect(notifications.statusChanged).toHaveBeenCalledWith(
        ORDER_ID,
        OrderStatus.DELIVERED,
      );
    });

    it('la entrega sigue valiendo aunque no arranque el regreso', async () => {
      flights.startReturn.mockRejectedValueOnce(new Error('sin Redis'));

      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
    });

    it('rechaza un código incorrecto sin entregar y cuenta el intento', async () => {
      await expect(
        service.validate(requester, ORDER_ID, WRONG),
      ).rejects.toThrow(new BadRequestException(DELIVERY_CODE_REJECTED));

      const [saved] = manager.save.mock.calls[0] as [DeliveryCode];
      expect(saved.attempts).toBe(1);
      expect(saved.usedAt).toBeNull();
      expect(current!.status).toBe(OrderStatus.AWAITING_DELIVERY);
      expect(flights.startReturn).not.toHaveBeenCalled();
      expect(notifications.statusChanged).not.toHaveBeenCalled();
    });

    it('bloquea el pedido al quinto intento fallido', async () => {
      stored = state({ attempts: DELIVERY_CODE_MAX_ATTEMPTS - 1 });

      await expect(
        service.validate(requester, ORDER_ID, WRONG),
      ).rejects.toThrow(new BadRequestException(DELIVERY_CODE_LOCKED));

      expect(stored.attempts).toBe(DELIVERY_CODE_MAX_ATTEMPTS);
    });

    it('con el pedido bloqueado ni el código correcto entrega', async () => {
      stored = state({ attempts: DELIVERY_CODE_MAX_ATTEMPTS });

      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_LOCKED),
      );

      expect(stored.usedAt).toBeNull();
      expect(flights.startReturn).not.toHaveBeenCalled();
    });

    it('el código correcto entrega aunque haya intentos fallidos previos', async () => {
      stored = state({ attempts: DELIVERY_CODE_MAX_ATTEMPTS - 1 });

      const result = await service.validate(requester, ORDER_ID, CODE);

      expect(result.status).toBe(OrderStatus.DELIVERED);
    });

    it('un código vencido no cuenta como intento', async () => {
      mission = {
        orderId: ORDER_ID,
        landedAt: new Date(Date.now() - DEFAULT_DELIVERY_WAIT_MS - 1000),
      } as Mission;
      stored = state();

      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );

      expect(stored.attempts).toBe(0);
    });

    it('rechaza un código ya usado', async () => {
      stored = state({ usedAt: new Date() });
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );
    });

    it('rechaza un segundo intento cuando el pedido ya está entregado', async () => {
      current = order({ status: OrderStatus.DELIVERED });
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(DELIVERY_CODE_REJECTED),
      );
    });

    it('rechaza un pedido que no está en espera de entrega', async () => {
      current = order({ status: OrderStatus.RETURNING });
      await expect(service.validate(requester, ORDER_ID, CODE)).rejects.toThrow(
        new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED),
      );
    });

    it('responde 404 si el pedido es de otro solicitante', async () => {
      current = order({ requesterId: 'otro' });
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

    it('el despachador de la central de destino ve el código y lo valida', async () => {
      current = hubOrder();
      const dispatcher = dispatcherOf(HUB_ID);

      const shown = await service.show(dispatcher, ORDER_ID);
      const result = await service.validate(dispatcher, ORDER_ID, shown.code);

      expect(result.status).toBe(OrderStatus.DELIVERED);
    });

    it('un despachador de otra central recibe 404', async () => {
      current = hubOrder();
      await expect(
        service.show(dispatcherOf('otra-central'), ORDER_ID),
      ).rejects.toThrow(NotFoundException);
    });

    it('el solicitante no recibe un pedido cuyo destino es una central', async () => {
      current = hubOrder();
      await expect(service.show(requester, ORDER_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('un despachador no recibe un pedido cuyo destino es una persona', async () => {
      await expect(
        service.show(dispatcherOf(HUB_ID), ORDER_ID),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
