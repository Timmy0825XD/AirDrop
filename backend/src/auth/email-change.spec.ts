import { BadRequestException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { OtpPurpose } from '../common/enums/otp-purpose.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { maskEmail } from '../mail/email-changed';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { hashOtp, hashPassword } from './auth.rules';
import {
  AuthService,
  CURRENT_PASSWORD_REQUIRED,
  CURRENT_PASSWORD_WRONG,
  NO_PENDING_EMAIL,
} from './auth.service';
import { OneTimeCode } from './one-time-code.entity';
import { OtpDeliveryService } from './otp-delivery.service';

const PASSWORD = 'Clave-Segura-2026';
const OLD = 'ana.perez@gmail.com';
const NEW = 'ana.nueva@gmail.com';

let passwordHash: string;

beforeAll(async () => {
  passwordHash = await hashPassword(PASSWORD);
});

function account(overrides: Partial<User> = {}): User {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    fullName: 'Ana Pérez',
    email: OLD,
    pendingEmail: null,
    phone: '3001234567',
    role: UserRole.REQUESTER,
    status: UserStatus.ACTIVE,
    passwordHash,
    ...overrides,
  } as User;
}

function build(state: { takenBy?: User | null; code?: string } = {}) {
  const codeRow = state.code
    ? ({
        codeHash: hashOtp(state.code),
        expiresAt: new Date(Date.now() + 60_000),
        consumedAt: null,
      } as OneTimeCode)
    : null;
  const users = {
    findByEmail: jest.fn().mockResolvedValue(state.takenBy ?? null),
    save: jest.fn((user: User) => Promise.resolve(user)),
    toPublicUser: jest.fn((user: User) => ({
      email: user.email,
      pendingEmail: user.pendingEmail,
    })),
  };
  const codes = {
    find: jest.fn().mockResolvedValue([]),
    findOne: jest.fn().mockResolvedValue(codeRow),
    create: jest.fn((value: object) => value),
    save: jest.fn((value: unknown) => Promise.resolve(value)),
  };
  const otpDelivery = {
    deliver: jest.fn().mockResolvedValue(undefined),
    notifyEmailChanged: jest.fn().mockResolvedValue(undefined),
  };
  const service = new AuthService(
    users as unknown as UsersService,
    codes as never,
    { sign: jest.fn() } as unknown as JwtService,
    otpDelivery as unknown as OtpDeliveryService,
  );
  return { service, users, codes, otpDelivery };
}

describe('AuthService cambio de correo', () => {
  it('el correo no cambia hasta confirmar: queda pendiente y el código va al correo nuevo', async () => {
    const user = account();
    const { service, otpDelivery } = build();
    const result = await service.updateProfile(user, {
      email: NEW,
      currentPassword: PASSWORD,
    });
    expect(result).toMatchObject({ email: OLD, pendingEmail: NEW });
    expect(user.email).toBe(OLD);
    expect(otpDelivery.deliver).toHaveBeenCalledWith(
      OtpPurpose.EMAIL_CHANGE,
      expect.stringMatching(/^\d{6}$/),
      { channel: 'email', email: NEW, name: 'Ana Pérez' },
    );
  });

  it('pide la contraseña actual y rechaza una equivocada con 400, no 401', async () => {
    const { service } = build();
    await expect(
      service.updateProfile(account(), { email: NEW }),
    ).rejects.toThrow(new BadRequestException(CURRENT_PASSWORD_REQUIRED));
    await expect(
      service.updateProfile(account(), {
        email: NEW,
        currentPassword: 'otra-clave',
      }),
    ).rejects.toThrow(new BadRequestException(CURRENT_PASSWORD_WRONG));
  });

  it('el mismo correo de siempre no pide contraseña ni manda código', async () => {
    const { service, otpDelivery } = build();
    await service.updateProfile(account(), { email: OLD, fullName: 'Ana P.' });
    expect(otpDelivery.deliver).not.toHaveBeenCalled();
  });

  it('un correo de otra cuenta responde 409', async () => {
    const { service } = build({ takenBy: account({ id: 'otra' }) });
    await expect(
      service.updateProfile(account(), {
        email: NEW,
        currentPassword: PASSWORD,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('con el código correcto cambia el correo y avisa al anterior', async () => {
    const user = account({ pendingEmail: NEW });
    const { service, otpDelivery } = build({ code: '123456' });
    const result = await service.confirmEmailChange(user, '123456');
    expect(result).toEqual({ email: NEW, pendingEmail: null });
    expect(otpDelivery.notifyEmailChanged).toHaveBeenCalledWith(
      { channel: 'email', email: OLD, name: 'Ana Pérez' },
      NEW,
    );
  });

  it('un código equivocado no cambia nada', async () => {
    const user = account({ pendingEmail: NEW });
    const { service, users } = build({ code: '123456' });
    await expect(service.confirmEmailChange(user, '654321')).rejects.toThrow(
      BadRequestException,
    );
    expect(user.email).toBe(OLD);
    expect(users.save).not.toHaveBeenCalled();
  });

  it('si otra cuenta tomó el correo mientras llegaba el código, 409', async () => {
    const user = account({ pendingEmail: NEW });
    const { service } = build({
      code: '123456',
      takenBy: account({ id: 'otra' }),
    });
    await expect(service.confirmEmailChange(user, '123456')).rejects.toThrow(
      ConflictException,
    );
    expect(user.email).toBe(OLD);
  });

  it('el cambio vale aunque no salga el aviso al correo anterior', async () => {
    const user = account({ pendingEmail: NEW });
    const { service, otpDelivery } = build({ code: '123456' });
    otpDelivery.notifyEmailChanged.mockRejectedValue(new Error('Brevo caído'));
    await expect(service.confirmEmailChange(user, '123456')).resolves.toEqual({
      email: NEW,
      pendingEmail: null,
    });
  });

  it('sin cambio pendiente no se confirma, reenvía ni cancela', async () => {
    const { service } = build({ code: '123456' });
    const error = new BadRequestException(NO_PENDING_EMAIL);
    await expect(
      service.confirmEmailChange(account(), '123456'),
    ).rejects.toThrow(error);
    await expect(service.resendEmailChangeOtp(account())).rejects.toThrow(
      error,
    );
    await expect(service.cancelEmailChange(account())).rejects.toThrow(error);
  });

  it('reenviar manda otro código al correo nuevo y cancelar deja el actual', async () => {
    const { service, otpDelivery } = build();
    await service.resendEmailChangeOtp(account({ pendingEmail: NEW }));
    expect(otpDelivery.deliver).toHaveBeenCalledWith(
      OtpPurpose.EMAIL_CHANGE,
      expect.any(String),
      expect.objectContaining({ email: NEW }),
    );
    const cancelled = await service.cancelEmailChange(
      account({ pendingEmail: NEW }),
    );
    expect(cancelled).toEqual({ email: OLD, pendingEmail: null });
  });
});

describe('maskEmail', () => {
  it('deja ver solo la primera y la última letra antes de la arroba', () => {
    expect(maskEmail('daniela@gmail.com')).toBe('d*****a@gmail.com');
    expect(maskEmail('al@gmail.com')).toBe('a***@gmail.com');
    expect(maskEmail('sin-arroba')).toBe('***');
  });
});
