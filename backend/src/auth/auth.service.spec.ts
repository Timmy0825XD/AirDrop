import { BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserStatus } from '../common/enums/user-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { hashOtp, OTP_LOCKED } from './auth.rules';
import { OtpDeliveryService } from './otp-delivery.service';
import { User } from '../users/user.entity';
import { OneTimeCode } from './one-time-code.entity';

describe('AuthService OTP consume', () => {
  const user = {
    id: '11111111-1111-1111-1111-111111111111',
    email: 'ana.perez@gmail.com',
    phone: null,
    status: UserStatus.UNVERIFIED,
    role: UserRole.REQUESTER,
    failedLoginCount: 0,
    lockedUntil: null,
  } as User;

  function buildService(codes: {
    findOne: jest.Mock;
    save: jest.Mock;
    increment?: jest.Mock;
    update?: jest.Mock;
  }): AuthService {
    return new AuthService(
      {
        findByEmail: jest.fn().mockResolvedValue(user),
        save: jest.fn(),
      } as unknown as UsersService,
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

  describe('H-08: intentos fallidos', () => {
    function openRow(attempts: number) {
      return {
        id: 'code-1',
        codeHash: hashOtp('123456'),
        expiresAt: new Date(Date.now() + 60_000),
        consumedAt: null,
        attempts,
      } as OneTimeCode;
    }

    function codesFor(row: OneTimeCode) {
      return {
        findOne: jest.fn().mockResolvedValue(row),
        save: jest.fn(),
        increment: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
      };
    }

    it('counts a wrong code without voiding it yet', async () => {
      const codes = codesFor(openRow(0));
      const service = buildService(codes);
      await expect(
        service.resetPassword({
          email: user.email ?? undefined,
          code: '000000',
          password: 'Nueva-Clave-2026',
        }),
      ).rejects.toThrow('El código es inválido o ya venció.');
      expect(codes.increment).toHaveBeenCalledWith(
        { id: 'code-1' },
        'attempts',
        1,
      );
      expect(codes.update).not.toHaveBeenCalled();
    });

    it('voids the code on the fifth wrong attempt', async () => {
      const codes = codesFor(openRow(4));
      const service = buildService(codes);
      await expect(
        service.resetPassword({
          email: user.email ?? undefined,
          code: '000000',
          password: 'Nueva-Clave-2026',
        }),
      ).rejects.toThrow(OTP_LOCKED);
      expect(codes.update).toHaveBeenCalledWith(
        { id: 'code-1' },
        { consumedAt: expect.any(Date) as Date },
      );
    });

    it('rejects a locked code even when it is right', async () => {
      const codes = codesFor(openRow(5));
      const service = buildService(codes);
      await expect(
        service.verifySignup({
          email: user.email ?? undefined,
          code: '123456',
        }),
      ).rejects.toThrow(OTP_LOCKED);
      expect(codes.increment).not.toHaveBeenCalled();
      expect(codes.save).not.toHaveBeenCalled();
    });
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
