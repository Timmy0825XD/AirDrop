import { ForbiddenException } from '@nestjs/common';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from './user.entity';
import { UsersService } from './users.service';

function user(overrides: Partial<User> = {}): User {
  return {
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    failedLoginCount: 0,
    lockedUntil: null,
    ...overrides,
  } as User;
}

describe('UsersService.setSuspension', () => {
  it('suspends an institutional account', async () => {
    const target = user({
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    });
    const users = {
      findOne: jest.fn().mockResolvedValue(target),
      save: jest.fn().mockImplementation((row: User) => Promise.resolve(row)),
    };
    const service = new UsersService(users as never);
    const result = await service.setSuspension(user({ role: UserRole.ADMIN }), target.id, true);
    expect(result.status).toBe(UserStatus.SUSPENDED);
  });

  it('rejects suspending a requester', async () => {
    const target = user({
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      role: UserRole.REQUESTER,
    });
    const users = {
      findOne: jest.fn().mockResolvedValue(target),
      save: jest.fn(),
    };
    const service = new UsersService(users as never);
    await expect(
      service.setSuspension(user({ role: UserRole.ADMIN }), target.id, true),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
