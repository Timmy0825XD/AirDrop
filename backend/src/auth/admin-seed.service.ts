import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { UsersService } from '../users/users.service';
import { hashPassword } from './auth.rules';

@Injectable()
export class AdminSeedService implements OnModuleInit {
  private readonly logger = new Logger(AdminSeedService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly config: ConfigService,
  ) {}

  async onModuleInit(): Promise<void> {
    const existing = await this.usersService.findByRole(UserRole.ADMIN);
    if (existing) {
      return;
    }
    const email = this.config.get<string>(
      'ADMIN_EMAIL',
      'administrador.plataforma@gmail.com',
    );
    // Sin valor por defecto (H-03): una contraseña escrita aquí es pública en
    // el repositorio. Sin ADMIN_PASSWORD no se crea la cuenta.
    const password = this.config.get<string>('ADMIN_PASSWORD')?.trim();
    if (!password) {
      this.logger.warn(
        'ADMIN_PASSWORD no está definida: no se crea la cuenta admin inicial.',
      );
      return;
    }
    const fullName = this.config.get<string>(
      'ADMIN_FULL_NAME',
      'Administrador AirDrop',
    );
    const user = this.usersService.create({
      fullName,
      email: email.toLowerCase(),
      phone: null,
      documentType: null,
      documentNumber: null,
      passwordHash: await hashPassword(password),
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
      consentAcceptedAt: new Date(),
      failedLoginCount: 0,
      lockedUntil: null,
    });
    await this.usersService.save(user);
    this.logger.log('Cuenta admin inicial creada');
  }
}
