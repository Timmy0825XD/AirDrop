import { BadRequestException, ConflictException, ForbiddenException } from '@nestjs/common';
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { CreateHubDto } from './dto/create-hub.dto';
import { Hub } from './hub.entity';
import { HubAdminNoticeService } from './hub-admin-notice.service';
import { HubsService } from './hubs.service';

const dto: CreateHubDto = {
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4631,
  longitude: -73.2532,
  contactPhone: '3001234567',
};

function dispatcher(overrides: Partial<User> = {}): User {
  return {
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubId: null,
    ...overrides,
  } as User;
}

function buildService(hubs: {
  findOne: jest.Mock;
  create: jest.Mock;
  save: jest.Mock;
}) {
  const save = jest.fn((user: User) => Promise.resolve(user));
  const notifyPendingApproval = jest.fn();
  const notifyDecision = jest.fn();
  const usersService = { save } as unknown as UsersService;
  const notice = {
    notifyPendingApproval,
    notifyDecision,
  } as unknown as HubAdminNoticeService;
  return {
    service: new HubsService(hubs as never, usersService, notice),
    save,
    notifyPendingApproval,
  };
}

describe('HubsService', () => {
  it('creates a hub in pending_approval and links the dispatcher', async () => {
    const savedHub = {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      ...dto,
      status: HubStatus.PENDING_APPROVAL,
      createdByUserId: dispatcher().id,
      createdAt: new Date(),
    } as Hub;
    const hubs = {
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockReturnValue(savedHub),
      save: jest.fn().mockResolvedValue(savedHub),
    };
    const { service, save, notifyPendingApproval } = buildService(hubs);
    const user = dispatcher();
    const result = await service.create(user, dto);
    expect(result.status).toBe(HubStatus.PENDING_APPROVAL);
    expect(user.hubId).toBe(savedHub.id);
    expect(save).toHaveBeenCalledWith(user);
    expect(notifyPendingApproval).toHaveBeenCalledWith(savedHub);
  });

  it('approves a pending hub', async () => {
    const pending = {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      status: HubStatus.PENDING_APPROVAL,
      rejectionReason: null,
      createdAt: new Date(),
      ...dto,
    } as Hub;
    const hubs = {
      findOne: jest.fn().mockResolvedValue(pending),
      create: jest.fn(),
      save: jest.fn().mockImplementation((row: Hub) => Promise.resolve(row)),
    };
    const { service } = buildService(hubs);
    const result = await service.decide(pending.id, {
      status: HubStatus.APPROVED,
    });
    expect(result.status).toBe(HubStatus.APPROVED);
  });

  it('requires a reason when rejecting', async () => {
    const pending = {
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      status: HubStatus.PENDING_APPROVAL,
    } as Hub;
    const { service } = buildService({
      findOne: jest.fn().mockResolvedValue(pending),
      create: jest.fn(),
      save: jest.fn(),
    });
    await expect(
      service.decide(pending.id, { status: HubStatus.REJECTED }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects a second hub for the same dispatcher', async () => {
    const { service } = buildService({
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    });
    await expect(
      service.create(dispatcher({ hubId: 'already' }), dto),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects an inactive account', async () => {
    const { service } = buildService({
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    });
    await expect(
      service.create(dispatcher({ status: UserStatus.UNVERIFIED }), dto),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
