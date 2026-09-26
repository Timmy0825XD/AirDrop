import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { hashPassword } from '../auth/auth.rules';
import { DocumentType } from '../common/enums/document-type.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { INSTITUTIONAL_ROLES, UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { CreateInstitutionalUserDto } from './dto/create-institutional-user.dto';
import { assignedHubIds } from './hub-assignment';
import { UserHubAssignment } from './user-hub-assignment.entity';
import { User } from './user.entity';

const WITH_HUBS = { hubAssignments: true } as const;

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(UserHubAssignment)
    private readonly assignments: Repository<UserHubAssignment>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
  ) {}

  findById(id: string): Promise<User | null> {
    return this.users.findOne({ where: { id }, relations: WITH_HUBS });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.users.findOne({ where: { email }, relations: WITH_HUBS });
  }

  findByPhone(phone: string): Promise<User | null> {
    return this.users.findOne({ where: { phone }, relations: WITH_HUBS });
  }

  findByDocument(
    documentType: DocumentType,
    documentNumber: string,
  ): Promise<User | null> {
    return this.users.findOne({
      where: { documentType, documentNumber },
      relations: WITH_HUBS,
    });
  }

  findByRole(role: User['role']): Promise<User | null> {
    return this.users.findOne({ where: { role } });
  }

  listInstitutional(filters: {
    role?: UserRole;
    status?: UserStatus;
    hubId?: string;
  }): Promise<User[]> {
    const roles = filters.role ? [filters.role] : [...INSTITUTIONAL_ROLES];
    const qb = this.users
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.hubAssignments', 'assignment')
      .where('user.role IN (:...roles)', { roles })
      .orderBy('user.fullName', 'ASC');
    if (filters.status) {
      qb.andWhere('user.status = :status', { status: filters.status });
    }
    if (filters.hubId) {
      qb.andWhere(
        `user.id IN (SELECT uh."userId" FROM user_hubs uh WHERE uh."hubId" = :hubId)`,
        { hubId: filters.hubId },
      );
    }
    return qb.getMany();
  }

  create(data: Partial<User>): User {
    return this.users.create(data);
  }

  save(user: User): Promise<User> {
    return this.users.save(user);
  }

  toPublicUser(user: User) {
    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      documentType: user.documentType,
      documentNumber: user.documentNumber,
      role: user.role,
      status: user.status,
      hubIds: assignedHubIds(user),
    };
  }

  async createInstitutional(
    actor: User,
    dto: CreateInstitutionalUserDto,
  ): Promise<User> {
    if (actor.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar usuarios.',
      );
    }
    if (!INSTITUTIONAL_ROLES.includes(dto.role)) {
      throw new BadRequestException(
        'El rol debe ser despachador u operador de flota.',
      );
    }
    const hubIds = [...new Set(dto.hubIds)];
    if (dto.role === UserRole.DISPATCHER && hubIds.length !== 1) {
      throw new BadRequestException(
        'El despachador debe quedar asignado a una sola central.',
      );
    }
    if (dto.role === UserRole.FLEET_OPERATOR && hubIds.length < 1) {
      throw new BadRequestException(
        'El operador debe quedar asignado al menos a una central.',
      );
    }
    const found = await this.hubs.find({ where: { id: In(hubIds) } });
    if (found.length !== hubIds.length) {
      throw new NotFoundException('La central no existe.');
    }
    if (found.some((hub) => hub.status !== HubStatus.ACTIVE)) {
      throw new BadRequestException('Solo puedes asignar centrales activas.');
    }
    await this.assertContactAvailable(dto.email, dto.phone);
    const user = this.users.create({
      fullName: dto.fullName.trim(),
      email: dto.email,
      phone: dto.phone ?? null,
      documentType: null,
      documentNumber: null,
      passwordHash: await hashPassword(dto.password),
      role: dto.role,
      status: UserStatus.ACTIVE,
      consentAcceptedAt: new Date(),
      failedLoginCount: 0,
      lockedUntil: null,
    });
    const saved = await this.users.save(user);
    saved.hubAssignments = await this.assignments.save(
      hubIds.map((hubId) => this.assignments.create({ userId: saved.id, hubId })),
    );
    return saved;
  }

  async setSuspension(
    actor: User,
    targetId: string,
    suspended: boolean,
  ): Promise<User> {
    if (actor.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar usuarios.',
      );
    }
    const target = await this.findById(targetId);
    if (!target) {
      throw new NotFoundException('El usuario no existe.');
    }
    if (!INSTITUTIONAL_ROLES.includes(target.role)) {
      throw new ForbiddenException(
        'Solo puedes suspender despachadores y operadores.',
      );
    }
    if (target.id === actor.id) {
      throw new ForbiddenException('No puedes suspender tu propia cuenta.');
    }
    if (suspended) {
      if (target.status === UserStatus.SUSPENDED) {
        throw new ConflictException('Esta cuenta ya está suspendida.');
      }
      if (
        target.status !== UserStatus.ACTIVE &&
        target.status !== UserStatus.LOCKED
      ) {
        throw new BadRequestException(
          'Solo se pueden suspender cuentas activas o bloqueadas.',
        );
      }
      target.status = UserStatus.SUSPENDED;
    } else {
      if (target.status !== UserStatus.SUSPENDED) {
        throw new ConflictException('Esta cuenta no está suspendida.');
      }
      target.status = UserStatus.ACTIVE;
      target.failedLoginCount = 0;
      target.lockedUntil = null;
    }
    await this.users.update(target.id, {
      status: target.status,
      failedLoginCount: target.failedLoginCount,
      lockedUntil: target.lockedUntil,
    });
    return target;
  }

  private async assertContactAvailable(
    email?: string,
    phone?: string,
  ): Promise<void> {
    if (email && (await this.findByEmail(email))) {
      throw new ConflictException(
        'Ya existe una cuenta con este correo o celular.',
      );
    }
    if (phone && (await this.findByPhone(phone))) {
      throw new ConflictException(
        'Ya existe una cuenta con este correo o celular.',
      );
    }
  }
}
