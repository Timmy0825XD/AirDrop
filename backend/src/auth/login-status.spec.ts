import { ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { hashPassword } from './auth.rules';
import { OtpDeliveryService } from './otp-delivery.service';

describe('Login preserves account restrictions after a temporary lock', () => {
  const password = 'SyntheticPass9';
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await hashPassword(password);
  });

  function fixture(status: UserStatus) {
    const user = {
      id: '11111111-1111-4111-8111-111111111111',
      email: 'audit@example.invalid',
      fullName: 'Synthetic account',
      role: UserRole.REQUESTER,
      status,
      passwordHash,
      failedLoginCount: 0,
      lockedUntil: null,
    } as User;
    const sign = jest.fn().mockReturnValue('synthetic-token');
    const deliver = jest.fn().mockResolvedValue(undefined);
    const codes = {
      find: jest.fn().mockResolvedValue([]),
      create: jest.fn((row: object) => row),
      save: jest.fn().mockImplementation((row: object) => Promise.resolve(row)),
    };
    const service = new AuthService(
      {
        findByEmail: jest.fn().mockResolvedValue(user),
        save: jest.fn().mockImplementation((row: User) => Promise.resolve(row)),
        toPublicUser: jest.fn((row: User) => ({
          id: row.id,
          status: row.status,
        })),
      } as unknown as UsersService,
      codes as never,
      { sign } as unknown as JwtService,
      { deliver } as unknown as OtpDeliveryService,
    );
    const login = (value: string) =>
      service.login({ email: user.email!, password: value });
    return { user, sign, deliver, login };
  }

  async function lock(login: (value: string) => Promise<unknown>) {
    for (let attempt = 0; attempt < 5; attempt++) {
      await expect(login('wrong-password')).rejects.toThrow();
    }
  }

  it.each([
    UserStatus.UNVERIFIED,
    UserStatus.SUSPENDED,
    UserStatus.REVOKED,
    UserStatus.DELETED,
  ])('does not reactivate a %s account after five failures', async (status) => {
    const { user, sign, deliver, login } = fixture(status);
    await lock(login);
    expect(user.lockedUntil).toBeInstanceOf(Date);
    await expect(login(password)).rejects.toBeInstanceOf(ForbiddenException);
    expect(sign).not.toHaveBeenCalled();

    user.lockedUntil = new Date(Date.now() - 1);
    await expect(login(password)).rejects.toBeInstanceOf(ForbiddenException);
    expect(user.status).toBe(status);
    expect(sign).not.toHaveBeenCalled();
    expect(deliver).toHaveBeenCalledTimes(
      status === UserStatus.UNVERIFIED ? 1 : 0,
    );
  });

  it('lets an active account log in again once its temporary lock expires', async () => {
    const { user, sign, login } = fixture(UserStatus.ACTIVE);
    await lock(login);
    await expect(login(password)).rejects.toBeInstanceOf(ForbiddenException);
    expect(sign).not.toHaveBeenCalled();

    user.lockedUntil = new Date(Date.now() - 1);
    await expect(login(password)).resolves.toMatchObject({
      accessToken: 'synthetic-token',
    });
    expect(user.status).toBe(UserStatus.ACTIVE);
    expect(user.failedLoginCount).toBe(0);
    expect(user.lockedUntil).toBeNull();
    expect(sign).toHaveBeenCalledTimes(1);
  });
});
