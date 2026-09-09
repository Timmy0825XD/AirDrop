import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { Hub } from '../hubs/hub.entity';
import { User } from '../users/user.entity';
import { CreateDroneDto } from './dto/create-drone.dto';
import { Drone } from './drone.entity';
import { DroneModel } from './drone-model.entity';
import { FleetService } from './fleet.service';
import { WINGCOPTER_198_CODE } from './drone-model-seed.service';

const model: DroneModel = {
  id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
  code: WINGCOPTER_198_CODE,
  name: 'Wingcopter 198',
  maxSpeedKmh: 150,
  maxPayloadKg: 6,
  maxRangeKm: 110,
};

const hub = { id: 'dddddddd-dddd-dddd-dddd-dddddddddddd' } as Hub;

const dto: CreateDroneDto = {
  identifier: 'WC-198-001',
  droneModelId: model.id,
  hubId: hub.id,
};

function operator(overrides: Partial<User> = {}): User {
  return {
    id: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    role: UserRole.FLEET_OPERATOR,
    status: UserStatus.ACTIVE,
    ...overrides,
  } as User;
}

function buildService(opts: {
  drones?: Partial<{ findOne: jest.Mock; create: jest.Mock; save: jest.Mock }>;
  models?: Partial<{ find: jest.Mock; findOne: jest.Mock }>;
  hub?: Hub | null;
}) {
  const saved: Drone = {
    id: 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    identifier: dto.identifier,
    droneModelId: model.id,
    hubId: hub.id,
    status: DroneStatus.AVAILABLE,
    createdAt: new Date(),
  } as Drone;
  const drones = {
    findOne: jest.fn().mockResolvedValue(null),
    create: jest.fn().mockReturnValue(saved),
    save: jest.fn().mockResolvedValue(saved),
    ...opts.drones,
  };
  const models = {
    find: jest.fn().mockResolvedValue([model]),
    findOne: jest.fn().mockResolvedValue(model),
    ...opts.models,
  };
  const hubsService = {
    findById: jest
      .fn()
      .mockResolvedValue(opts.hub === undefined ? hub : opts.hub),
  } as unknown as HubsService;
  return {
    service: new FleetService(drones as never, models as never, hubsService),
    drones,
    models,
    hubsService,
    saved,
  };
}

describe('FleetService', () => {
  it('lists seeded-style models', async () => {
    const { service } = buildService({});
    const rows = await service.listModels();
    expect(rows[0].code).toBe(WINGCOPTER_198_CODE);
  });

  it('creates a drone as available', async () => {
    const { service } = buildService({});
    const result = await service.createDrone(operator(), dto);
    expect(result.status).toBe(DroneStatus.AVAILABLE);
    expect(result.identifier).toBe(dto.identifier);
  });

  it('rejects a duplicate identifier', async () => {
    const { service } = buildService({
      drones: { findOne: jest.fn().mockResolvedValue({ id: 'dup' }) },
    });
    await expect(service.createDrone(operator(), dto)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('rejects a missing hub', async () => {
    const { service } = buildService({ hub: null });
    await expect(service.createDrone(operator(), dto)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('rejects an inactive operator', async () => {
    const { service } = buildService({});
    await expect(
      service.createDrone(operator({ status: UserStatus.UNVERIFIED }), dto),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
