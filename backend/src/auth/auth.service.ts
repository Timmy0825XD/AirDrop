import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
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
  nextFailedLoginState,
  normalizeDocumentNumber,
  passwordsMatch,
} from './auth.rules';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ResendOtpDto } from './dto/resend-otp.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtPayload } from './jwt-payload';
import { OneTimeCode } from './one-time-code.entity';
import { OtpDeliveryService, OtpDestination } from './otp-delivery.service';

const GENERIC_RESET_MESSAGE = 'Si el contacto existe, te enviaremos un código.';

const EMAIL_TAKEN = 'Ya existe una cuenta con este correo o celular.';
export const CURRENT_PASSWORD_REQUIRED =
  'Para cambiar el correo escribe tu contraseña actual.';
// 400 y no 401: ante un 401 la app cierra la sesión.
export const CURRENT_PASSWORD_WRONG = 'La contraseña actual no es correcta.';
export const NO_PENDING_EMAIL = 'No hay un cambio de correo pendiente.';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly usersService: UsersService,
    @InjectRepository(OneTimeCode)
    private readonly codes: Repository<OneTimeCode>,
    private readonly jwt: JwtService,
    private readonly otpDelivery: OtpDeliveryService,
  ) {}

  async register(dto: RegisterDto) {
    const documentNumber = normalizeDocumentNumber(
      dto.documentType,
      dto.documentNumber,
    );
    if (!documentNumber) {
      throw new BadRequestException(
        'El número de documento no corresponde a una cédula o a un PPT.',
      );
    }
    if (
      await this.usersService.findByDocument(dto.documentType, documentNumber)
    ) {
      throw new ConflictException('Ya existe una cuenta con este documento.');
    }
    await this.assertContactAvailable(dto.email, dto.phone);
    const passwordHash = await hashPassword(dto.password);
    const user = this.usersService.create({
      fullName: dto.fullName.trim(),
      email: dto.email,
      phone: dto.phone,
      documentType: dto.documentType,
      documentNumber,
      passwordHash,
      role: UserRole.REQUESTER,
      status: UserStatus.UNVERIFIED,
      consentAcceptedAt: new Date(),
      failedLoginCount: 0,
      lockedUntil: null,
    });
    const saved = await this.usersService.save(user);
    const otp = await this.issueOtp(
      saved,
      OtpPurpose.SIGNUP,
      OTP_SIGNUP_TTL_MS,
      this.signupDestination(saved),
    );
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
    const otp = await this.issueOtp(
      user,
      OtpPurpose.SIGNUP,
      OTP_SIGNUP_TTL_MS,
      this.signupDestination(user),
    );
    return this.withOptionalOtp(
      { message: 'Si el contacto existe, te enviaremos un código.' },
      otp,
    );
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException(
        'El correo y la contraseña no coinciden.',
      );
    }
    if (isLockActive(user)) {
      throw new ForbiddenException(
        'Demasiados intentos. Intenta de nuevo en unos minutos.',
      );
    }
    if (user.status === UserStatus.LOCKED && !isLockActive(user)) {
      Object.assign(user, clearLockState(user.status));
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
        'El correo y la contraseña no coinciden.',
      );
    }
    if (user.status === UserStatus.UNVERIFIED) {
      await this.issueOtp(
        user,
        OtpPurpose.SIGNUP,
        OTP_SIGNUP_TTL_MS,
        this.signupDestination(user),
      );
      throw new ForbiddenException({
        message:
          'Debes verificar tu cuenta. Te enviamos un código nuevo a tu correo.',
        code: 'account_unverified',
      });
    }
    if (user.status === UserStatus.SUSPENDED) {
      throw new ForbiddenException(
        'Tu cuenta está suspendida. Habla con el administrador.',
      );
    }
    Object.assign(user, clearLockState(user.status));
    await this.usersService.save(user);
    return this.tokenResponse(user);
  }

  logout(): void {
    return;
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.findUserByContact(dto.email, dto.phone);
    if (user) {
      if (!user.email) {
        return { message: GENERIC_RESET_MESSAGE };
      }
      const destination: OtpDestination = {
        channel: 'email',
        email: user.email,
        name: user.fullName,
      };
      const otp = await this.issueOtp(
        user,
        OtpPurpose.PASSWORD_RESET,
        OTP_RESET_TTL_MS,
        destination,
      );
      return this.withOptionalOtp({ message: GENERIC_RESET_MESSAGE }, otp);
    }
    return { message: GENERIC_RESET_MESSAGE };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.requireUserByContact(dto.email, dto.phone);
    await this.consumeOtp(user, OtpPurpose.PASSWORD_RESET, dto.code);
    user.passwordHash = await hashPassword(dto.password);
    Object.assign(user, clearLockState(user.status));
    await this.usersService.save(user);
    return { message: 'La contraseña se actualizó. Ya puedes iniciar sesión.' };
  }

  toPublicUser(user: User) {
    return this.usersService.toPublicUser(user);
  }

  async updateProfile(user: User, dto: UpdateProfileDto) {
    if (
      dto.fullName === undefined &&
      dto.email === undefined &&
      dto.phone === undefined &&
      dto.documentType === undefined &&
      dto.documentNumber === undefined
    ) {
      throw new BadRequestException(
        'Debes enviar al menos un campo para actualizar.',
      );
    }
    if (dto.fullName !== undefined) {
      const fullName = dto.fullName.trim();
      if (!fullName) {
        throw new BadRequestException('El nombre es obligatorio.');
      }
      user.fullName = fullName;
    }
    // RNF de seguridad: el correo nuevo no reemplaza al actual hasta
    // confirmarlo con el código que le llega (POST /auth/me/email/confirm).
    const newEmail =
      dto.email !== undefined && dto.email !== user.email ? dto.email : null;
    if (newEmail) {
      if (!dto.currentPassword) {
        throw new BadRequestException(CURRENT_PASSWORD_REQUIRED);
      }
      if (!(await passwordsMatch(dto.currentPassword, user.passwordHash))) {
        throw new BadRequestException(CURRENT_PASSWORD_WRONG);
      }
      await this.assertEmailFree(user, newEmail);
      user.pendingEmail = newEmail;
    }
    if (dto.phone !== undefined) {
      const taken = await this.usersService.findByPhone(dto.phone);
      if (taken && taken.id !== user.id) {
        throw new ConflictException(
          'Ya existe una cuenta con este correo o celular.',
        );
      }
      user.phone = dto.phone;
    }
    if (dto.documentType !== undefined || dto.documentNumber !== undefined) {
      if (user.role !== UserRole.REQUESTER) {
        throw new BadRequestException(
          'El documento solo aplica al solicitante.',
        );
      }
      if (!dto.documentType || !dto.documentNumber) {
        throw new BadRequestException(
          'El tipo y el número de documento se actualizan juntos.',
        );
      }
      const documentNumber = normalizeDocumentNumber(
        dto.documentType,
        dto.documentNumber,
      );
      if (!documentNumber) {
        throw new BadRequestException(
          'El número de documento no corresponde a una cédula o a un PPT.',
        );
      }
      const taken = await this.usersService.findByDocument(
        dto.documentType,
        documentNumber,
      );
      if (taken && taken.id !== user.id) {
        throw new ConflictException('Ya existe una cuenta con este documento.');
      }
      user.documentType = dto.documentType;
      user.documentNumber = documentNumber;
    }
    const saved = await this.usersService.save(user);
    if (!newEmail) {
      return this.toPublicUser(saved);
    }
    const otp = await this.issueEmailChangeOtp(saved);
    return this.withOptionalOtp(this.toPublicUser(saved), otp);
  }

  /** Cambia el correo cuando llega el código y avisa al correo anterior. */
  async confirmEmailChange(user: User, code: string) {
    const pending = user.pendingEmail;
    if (!pending) {
      throw new BadRequestException(NO_PENDING_EMAIL);
    }
    await this.consumeOtp(user, OtpPurpose.EMAIL_CHANGE, code);
    // Otra cuenta pudo tomarlo mientras llegaba el código.
    await this.assertEmailFree(user, pending);
    const previous = user.email;
    user.email = pending;
    user.pendingEmail = null;
    const saved = await this.usersService.save(user);
    if (previous) {
      try {
        await this.otpDelivery.notifyEmailChanged(
          { channel: 'email', email: previous, name: saved.fullName },
          pending,
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : 'correo';
        this.logger.warn(`No se pudo avisar del cambio de correo: ${message}`);
      }
    }
    return this.toPublicUser(saved);
  }

  async resendEmailChangeOtp(user: User) {
    if (!user.pendingEmail) {
      throw new BadRequestException(NO_PENDING_EMAIL);
    }
    const otp = await this.issueEmailChangeOtp(user);
    return this.withOptionalOtp(
      { message: 'Te enviamos un código nuevo al correo nuevo.' },
      otp,
    );
  }

  /** Cancela el cambio: el correo actual sigue igual. */
  async cancelEmailChange(user: User) {
    if (!user.pendingEmail) {
      throw new BadRequestException(NO_PENDING_EMAIL);
    }
    user.pendingEmail = null;
    const saved = await this.usersService.save(user);
    return this.toPublicUser(saved);
  }

  private issueEmailChangeOtp(user: User): Promise<string> {
    return this.issueOtp(user, OtpPurpose.EMAIL_CHANGE, OTP_SIGNUP_TTL_MS, {
      channel: 'email',
      email: user.pendingEmail as string,
      name: user.fullName,
    });
  }

  private async assertEmailFree(user: User, email: string): Promise<void> {
    const taken = await this.usersService.findByEmail(email);
    if (taken && taken.id !== user.id) {
      throw new ConflictException(EMAIL_TAKEN);
    }
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

  private signupDestination(user: User): OtpDestination {
    if (!user.email) {
      throw new BadRequestException(
        'Esta cuenta no tiene correo para el código.',
      );
    }
    return { channel: 'email', email: user.email, name: user.fullName };
  }

  private async issueOtp(
    user: User,
    purpose: OtpPurpose,
    ttlMs: number,
    destination: OtpDestination,
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
    await this.otpDelivery.deliver(purpose, code, destination);
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
