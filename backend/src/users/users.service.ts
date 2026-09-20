import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, In, Repository } from 'typeorm';
import { INSTITUTIONAL_ROLES, UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  findById(id: string): Promise<User | null> {
    return this.users.findOne({ where: { id } });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.users.findOne({ where: { email } });
  }

  findByPhone(phone: string): Promise<User | null> {
    return this.users.findOne({ where: { phone } });
  }

  findByRole(role: User['role']): Promise<User | null> {
    return this.users.findOne({ where: { role } });
  }

  listInstitutional(filters: {
    role?: UserRole;
    status?: UserStatus;
    hubId?: string;
  }): Promise<User[]> {
    const where: FindOptionsWhere<User> = {
      role: filters.role ? filters.role : In(INSTITUTIONAL_ROLES),
    };
    if (filters.status) {
      where.status = filters.status;
    }
    if (filters.hubId) {
      where.hubId = filters.hubId;
    }
    return this.users.find({
      where,
      order: { fullName: 'ASC' },
    });
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
      role: user.role,
      status: user.status,
      hubId: user.hubId,
    };
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
    return this.save(target);
  }
}
