import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { Hub } from './hub.entity';

@Injectable()
export class HubsService {
  constructor(
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
  ) {}

  async create(user: User, dto: CreateHubDto) {
    this.assertActiveAdmin(user);
    const hub = this.hubs.create({
      name: dto.name.trim(),
      type: dto.type,
      address: dto.address.trim(),
      latitude: dto.latitude,
      longitude: dto.longitude,
      contactPhone: dto.contactPhone,
      contactEmail: dto.contactEmail ?? null,
      status: HubStatus.ACTIVE,
      createdByUserId: user.id,
    });
    const saved = await this.hubs.save(hub);
    return this.toPublicHub(saved);
  }

  async findMine(user: User) {
    this.assertActiveAccount(user);
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException('Solo el despachador tiene una central.');
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new NotFoundException('No tienes una central asignada.');
    }
    const hub = await this.hubs.findOne({ where: { id: hubIds[0] } });
    if (!hub) {
      throw new NotFoundException('No tienes una central asignada.');
    }
    return this.toPublicHub(hub);
  }

  async listForAdmin(status?: HubStatus) {
    const rows = await this.hubs.find({
      where: status ? { status } : {},
      order: { createdAt: 'DESC' },
    });
    return rows.map((row) => this.toPublicHub(row));
  }

  async listAssigned(user: User) {
    this.assertActiveAccount(user);
    const hubIds = assignedHubIds(user);
    if (!hubIds.length) {
      return [];
    }
    const rows = await this.hubs.find({
      where: { id: In(hubIds) },
      order: { name: 'ASC' },
    });
    return rows.map((row) => this.toPublicHub(row));
  }

  async setSuspension(hubId: string, suspended: boolean) {
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    const next = suspended ? HubStatus.SUSPENDED : HubStatus.ACTIVE;
    if (hub.status === next) {
      throw new ConflictException(
        suspended
          ? 'Esta central ya está suspendida.'
          : 'Esta central ya está activa.',
      );
    }
    hub.status = next;
    const saved = await this.hubs.save(hub);
    return this.toPublicHub(saved);
  }

  findById(id: string): Promise<Hub | null> {
    return this.hubs.findOne({ where: { id } });
  }

  async requireActive(id: string): Promise<Hub> {
    const hub = await this.findById(id);
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    if (hub.status !== HubStatus.ACTIVE) {
      throw new ForbiddenException('La central está suspendida.');
    }
    return hub;
  }

  toPublicHub(hub: Hub) {
    return {
      id: hub.id,
      name: hub.name,
      type: hub.type,
      address: hub.address,
      latitude: hub.latitude,
      longitude: hub.longitude,
      contactPhone: hub.contactPhone,
      contactEmail: hub.contactEmail,
      status: hub.status,
      createdAt: hub.createdAt,
    };
  }

  private assertActiveAdmin(user: User): void {
    this.assertActiveAccount(user);
    if (user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Solo el administrador crea centrales.');
    }
  }

  private assertActiveAccount(user: User): void {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar la central.',
      );
    }
  }
}
