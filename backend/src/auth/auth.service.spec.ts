import { BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserStatus } from '../common/enums/user-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { hashOtp } from './auth.rules';
import { OtpDeliveryService } from './otp-delivery.service';
import { User } from '../users/user.entity';
import { OneTimeCode } from './one-time-code.entity';

describe('AuthService OTP consume', () => {
  const user = {
    id: '11111111-1111-1111-1111-111111111111',
    email: 'ana@correo.co',
    phone: null,
    status: UserStatus.UNVERIFIED,
    role: UserRole.REQUESTER,
    failedLoginCount: 0,
    lockedUntil: null,
  } as User;

  function buildService(codes: {
    findOne: jest.Mock;
    save: jest.Mock;
  }): AuthService {
    return new AuthService(
      { findByEmail: jest.fn().mockResolvedValue(user), save: jest.fn() } as unknown as UsersService,
      codes as never,
      { sign: jest.fn().mockReturnValue('token') } as unknown as JwtService,
      { deliver: jest.fn() } as unknown as OtpDeliveryService,
    );
  }

  it('rejects an expired signup OTP', async () => {
    const row = {
      codeHash: hashOtp('123456'),
      expiresAt: new Date(Date.now() - 1000),
      consumedAt: null,
    } as OneTimeCode;
    const codes = {
      findOne: jest.fn().mockResolvedValue(row),
      save: jest.fn(),
    };
    const service = buildService(codes);
    await expect(
      service.verifySignup({ email: user.email ?? undefined, code: '123456' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(codes.save).not.toHaveBeenCalled();
  });

  it('rejects a reused signup OTP', async () => {
    const codes = {
      findOne: jest.fn().mockResolvedValue(null),
      save: jest.fn(),
    };
    const service = buildService(codes);
    await expect(
      service.verifySignup({ email: user.email ?? undefined, code: '123456' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
