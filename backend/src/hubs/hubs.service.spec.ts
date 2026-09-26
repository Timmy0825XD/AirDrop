import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { Hub } from './hub.entity';
import { HubsService } from './hubs.service';

const dto: CreateHubDto = {
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4631,
  longitude: -73.2532,
  contactPhone: '3001234567',
};

function admin(overrides: Partial<User> = {}): User {
  return {
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    role: UserRole.ADMIN,
    status: UserStatus.ACTIVE,
    ...overrides,
  } as User;
}

function buildService(hubs: {
  findOne: jest.Mock;
  create: jest.Mock;
  save: jest.Mock;
}) {
  return new HubsService(hubs as never);
}

describe('HubsService', () => {
  it('creates a hub already active', async () => {
    const savedHub = {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      ...dto,
      status: HubStatus.ACTIVE,
      createdByUserId: admin().id,
      createdAt: new Date(),
    } as Hub;
    const hubs = {
      findOne: jest.fn(),
      create: jest.fn().mockReturnValue(savedHub),
      save: jest.fn().mockResolvedValue(savedHub),
    };
    const result = await buildService(hubs).create(admin(), dto);
    expect(result.status).toBe(HubStatus.ACTIVE);
    expect(result.name).toBe(dto.name);
    expect(hubs.save).toHaveBeenCalled();
  });

  it('suspends an active hub and rejects a second suspension', async () => {
    const hub = {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      status: HubStatus.ACTIVE,
      createdAt: new Date(),
      ...dto,
    } as Hub;
    const hubs = {
      findOne: jest.fn().mockResolvedValue(hub),
      create: jest.fn(),
      save: jest.fn().mockImplementation((row: Hub) => Promise.resolve(row)),
    };
    const service = buildService(hubs);
    const suspended = await service.setSuspension(hub.id, true);
    expect(suspended.status).toBe(HubStatus.SUSPENDED);
    await expect(service.setSuspension(hub.id, true)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('rejects inventory-style use of a suspended hub', async () => {
    const hub = {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      status: HubStatus.SUSPENDED,
    } as Hub;
    const service = buildService({
      findOne: jest.fn().mockResolvedValue(hub),
      create: jest.fn(),
      save: jest.fn(),
    });
    await expect(service.requireActive(hub.id)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('returns not found when the hub does not exist', async () => {
    const service = buildService({
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn(),
      save: jest.fn(),
    });
    await expect(
      service.requireActive('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects an inactive admin', async () => {
    const service = buildService({
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    });
    await expect(
      service.create(admin({ status: UserStatus.SUSPENDED }), dto),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
