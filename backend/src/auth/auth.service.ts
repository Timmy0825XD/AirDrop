import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { OtpPurpose } from '../common/enums/otp-purpose.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { OTP_RESET_TTL_MS, OTP_SIGNUP_TTL_MS } from '../common/field-limits';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import {
  clearLockState,
  generateOtp,
  hashOtp,
  hashPassword,
  isLockActive,
  isOtpConsumed,
  isOtpExpired,
  isPublicRegisterRole,
  nextFailedLoginState,
  passwordsMatch,
  requiresInstitutionalEmail,
} from './auth.rules';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ResendOtpDto } from './dto/resend-otp.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtPayload } from './jwt-payload';
import { OneTimeCode } from './one-time-code.entity';
import { OtpDeliveryService } from './otp-delivery.service';

const GENERIC_RESET_MESSAGE =
  'Si el contacto existe, te enviaremos un código.';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    @InjectRepository(OneTimeCode)
    private readonly codes: Repository<OneTimeCode>,
    private readonly jwt: JwtService,
    private readonly otpDelivery: OtpDeliveryService,
  ) {}

  async register(dto: RegisterDto) {
    if (!isPublicRegisterRole(dto.role)) {
      throw new BadRequestException('El rol no es válido para el registro.');
    }
    if (requiresInstitutionalEmail(dto.role) && !dto.email) {
      throw new BadRequestException(
        'El despachador y el operador deben registrarse con correo institucional.',
      );
    }
    await this.assertContactAvailable(dto.email, dto.phone);
    const passwordHash = await hashPassword(dto.password);
    const user = this.usersService.create({
      fullName: dto.fullName.trim(),
      email: dto.email ?? null,
      phone: dto.phone ?? null,
      passwordHash,
      role: dto.role,
      status: UserStatus.UNVERIFIED,
      consentAcceptedAt: new Date(),
      failedLoginCount: 0,
      lockedUntil: null,
    });
    const saved = await this.usersService.save(user);
    const otp = await this.issueOtp(saved, OtpPurpose.SIGNUP, OTP_SIGNUP_TTL_MS);
    return this.withOptionalOtp(
      {
        message: 'Cuenta creada. Verifica el código para activarla.',
        userId: saved.id,
      },
      otp,
    );
  }

  async verifySignup(dto: VerifyOtpDto) {
    const user = await this.requireUserByContact(dto.email, dto.phone);
    await this.consumeOtp(user, OtpPurpose.SIGNUP, dto.code);
    user.status = UserStatus.ACTIVE;
    user.failedLoginCount = 0;
    user.lockedUntil = null;
    await this.usersService.save(user);
    return this.tokenResponse(user);
  }

  async resendSignupOtp(dto: ResendOtpDto) {
    const user = await this.requireUserByContact(dto.email, dto.phone);
    if (user.status !== UserStatus.UNVERIFIED) {
      throw new BadRequestException('Esta cuenta ya está verificada.');
    }
    const otp = await this.issueOtp(user, OtpPurpose.SIGNUP, OTP_SIGNUP_TTL_MS);
    return this.withOptionalOtp(
      { message: 'Si el contacto existe, te enviaremos un código.' },
      otp,
    );
  }

  async login(dto: LoginDto) {
    const user = await this.findUserByContact(dto.email, dto.phone);
    if (!user) {
      throw new UnauthorizedException(
        'Correo o celular y contraseña no coinciden.',
      );
    }
    if (isLockActive(user)) {
      throw new ForbiddenException(
        'Demasiados intentos. Intenta de nuevo en unos minutos.',
      );
    }
    if (user.status === UserStatus.LOCKED && !isLockActive(user)) {
      Object.assign(user, clearLockState());
    }
    const matches = await passwordsMatch(dto.password, user.passwordHash);
    if (!matches) {
      Object.assign(user, nextFailedLoginState(user));
      await this.usersService.save(user);
      if (isLockActive(user)) {
        throw new ForbiddenException(
          'Demasiados intentos. Intenta de nuevo en unos minutos.',
        );
      }
      throw new UnauthorizedException(
        'Correo o celular y contraseña no coinciden.',
      );
    }
    if (user.status === UserStatus.UNVERIFIED) {
      throw new ForbiddenException(
        'Debes verificar tu cuenta con el código que te enviamos.',
      );
    }
    Object.assign(user, clearLockState());
    await this.usersService.save(user);
    return this.tokenResponse(user);
  }

  logout(): void {
    return;
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.findUserByContact(dto.email, dto.phone);
    if (user) {
      const otp = await this.issueOtp(
        user,
        OtpPurpose.PASSWORD_RESET,
        OTP_RESET_TTL_MS,
      );
      return this.withOptionalOtp({ message: GENERIC_RESET_MESSAGE }, otp);
    }
    return { message: GENERIC_RESET_MESSAGE };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.requireUserByContact(dto.email, dto.phone);
    await this.consumeOtp(user, OtpPurpose.PASSWORD_RESET, dto.code);
    user.passwordHash = await hashPassword(dto.password);
    Object.assign(user, clearLockState());
    await this.usersService.save(user);
    return { message: 'La contraseña se actualizó. Ya puedes iniciar sesión.' };
  }

  toPublicUser(user: User) {
    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
    };
  }

  private tokenResponse(user: User) {
    const payload: JwtPayload = { sub: user.id, role: user.role };
    return {
      accessToken: this.jwt.sign(payload),
      user: this.toPublicUser(user),
    };
  }

  private withOptionalOtp<T extends object>(body: T, otp: string): T {
    if (process.env.NODE_ENV === 'test') {
      return { ...body, otp };
    }
    return body;
  }

  private async assertContactAvailable(
    email?: string,
    phone?: string,
  ): Promise<void> {
    if (email && (await this.usersService.findByEmail(email))) {
      throw new ConflictException(
        'Ya existe una cuenta con este correo o celular.',
      );
    }
    if (phone && (await this.usersService.findByPhone(phone))) {
      throw new ConflictException(
        'Ya existe una cuenta con este correo o celular.',
      );
    }
  }

  private async findUserByContact(
    email?: string,
    phone?: string,
  ): Promise<User | null> {
    if (email) {
      return this.usersService.findByEmail(email);
    }
    if (phone) {
      return this.usersService.findByPhone(phone);
    }
    return null;
  }

  private async requireUserByContact(
    email?: string,
    phone?: string,
  ): Promise<User> {
    const user = await this.findUserByContact(email, phone);
    if (!user) {
      throw new BadRequestException('El código es inválido o ya venció.');
    }
    return user;
  }

  private async issueOtp(
    user: User,
    purpose: OtpPurpose,
    ttlMs: number,
  ): Promise<string> {
    const open = await this.codes.find({
      where: { userId: user.id, purpose, consumedAt: IsNull() },
    });
    const now = new Date();
    for (const row of open) {
      row.consumedAt = now;
    }
    if (open.length) {
      await this.codes.save(open);
    }
    const code = generateOtp();
    const row = this.codes.create({
      userId: user.id,
      purpose,
      codeHash: hashOtp(code),
      expiresAt: new Date(now.getTime() + ttlMs),
      consumedAt: null,
    });
    await this.codes.save(row);
    this.otpDelivery.deliver(purpose, code);
    return code;
  }

  private async consumeOtp(
    user: User,
    purpose: OtpPurpose,
    code: string,
  ): Promise<void> {
    const row = await this.codes.findOne({
      where: { userId: user.id, purpose, consumedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
    const invalid = () =>
      new BadRequestException('El código es inválido o ya venció.');
    if (!row || isOtpConsumed(row.consumedAt) || isOtpExpired(row.expiresAt)) {
      throw invalid();
    }
    if (row.codeHash !== hashOtp(code)) {
      throw invalid();
    }
    row.consumedAt = new Date();
    await this.codes.save(row);
  }
}
