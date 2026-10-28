import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Drone } from '../fleet/drone.entity';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { Hub } from './hub.entity';
import {
  COORDINATES_TOGETHER,
  EMPTY_HUB_UPDATE,
  HUB_HAS_LIVE_ORDERS,
  HUB_INSIDE_GEOFENCE,
} from './hubs.rules';
import { HubsService } from './hubs.service';

const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

function admin(overrides: Partial<User> = {}): User {
  return {
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    role: UserRole.ADMIN,
    status: UserStatus.ACTIVE,
    ...overrides,
  } as User;
}

function build(
  state: {
    hub?: Hub | null;
    liveOrders?: boolean;
    flyingDrones?: boolean;
    insideGeofence?: boolean;
  } = {},
) {
  const hub =
    state.hub === undefined
      ? ({
          id: HUB_ID,
          name: 'Hospital Rosario',
          type: HubType.HOSPITAL,
          address: 'Calle 16 # 10-20',
          latitude: 10.47,
          longitude: -73.26,
          contactPhone: '3001234567',
          contactEmail: null,
          status: HubStatus.ACTIVE,
        } as Hub)
      : state.hub;
  const manager = {
    exists: jest.fn((entity: unknown) =>
      Promise.resolve(
        entity === Order
          ? (state.liveOrders ?? false)
          : entity === Drone
            ? (state.flyingDrones ?? false)
            : false,
      ),
    ),
    query: jest
      .fn()
      .mockResolvedValue([{ inside: state.insideGeofence ?? false }]),
  };
  const hubs = {
    findOne: jest.fn().mockResolvedValue(hub),
    save: jest.fn((value: Hub) => Promise.resolve(value)),
    manager,
  };
  return { service: new HubsService(hubs as never), hubs, manager, hub };
}

describe('HubsService.update', () => {
  it('corrige nombre, dirección y contacto sin revisar vuelos', async () => {
    const { service, manager } = build();
    const result = await service.update(admin(), HUB_ID, {
      name: '  Hospital Rosario Pumarejo ',
      address: 'Calle 16 # 17-141',
      contactPhone: '3009876543',
    });
    expect(result).toMatchObject({
      name: 'Hospital Rosario Pumarejo',
      address: 'Calle 16 # 17-141',
      contactPhone: '3009876543',
      latitude: 10.47,
    });
    expect(manager.exists).not.toHaveBeenCalled();
    expect(manager.query).not.toHaveBeenCalled();
  });

  it('mueve la central libre a un punto fuera de geovallas', async () => {
    const { service, manager } = build();
    const result = await service.update(admin(), HUB_ID, {
      latitude: 10.48,
      longitude: -73.25,
    });
    expect(result).toMatchObject({ latitude: 10.48, longitude: -73.25 });
    expect(manager.query).toHaveBeenCalledWith(
      expect.any(String),
      [-73.25, 10.48],
    );
  });

  it('las mismas coordenadas no cuentan como mover', async () => {
    const { service, manager } = build({ liveOrders: true });
    await service.update(admin(), HUB_ID, {
      latitude: 10.47,
      longitude: -73.26,
      name: 'Hospital Rosario',
    });
    expect(manager.exists).not.toHaveBeenCalled();
  });

  it('no mueve una central con pedidos o drones en curso', async () => {
    for (const state of [{ liveOrders: true }, { flyingDrones: true }]) {
      const { service, hubs } = build(state);
      await expect(
        service.update(admin(), HUB_ID, { latitude: 10.5, longitude: -73.2 }),
      ).rejects.toThrow(new ConflictException(HUB_HAS_LIVE_ORDERS));
      expect(hubs.save).not.toHaveBeenCalled();
    }
  });

  it('no la deja dentro de una geovalla', async () => {
    const { service, hubs } = build({ insideGeofence: true });
    await expect(
      service.update(admin(), HUB_ID, { latitude: 10.5, longitude: -73.2 }),
    ).rejects.toThrow(new BadRequestException(HUB_INSIDE_GEOFENCE));
    expect(hubs.save).not.toHaveBeenCalled();
  });

  it('rechaza un body vacío y una coordenada sola', async () => {
    const { service } = build();
    await expect(service.update(admin(), HUB_ID, {})).rejects.toThrow(
      new BadRequestException(EMPTY_HUB_UPDATE),
    );
    await expect(
      service.update(admin(), HUB_ID, { latitude: 10.5 }),
    ).rejects.toThrow(new BadRequestException(COORDINATES_TOGETHER));
  });

  it('central inexistente, otro rol o cuenta suspendida', async () => {
    await expect(
      build({ hub: null }).service.update(admin(), HUB_ID, { name: 'X' }),
    ).rejects.toThrow(NotFoundException);
    await expect(
      build().service.update(admin({ role: UserRole.DISPATCHER }), HUB_ID, {
        name: 'X',
      }),
    ).rejects.toThrow(ForbiddenException);
    await expect(
      build().service.update(admin({ status: UserStatus.SUSPENDED }), HUB_ID, {
        name: 'X',
      }),
    ).rejects.toThrow(ForbiddenException);
  });
});
