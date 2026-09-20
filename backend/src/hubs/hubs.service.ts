import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HubStatus } from '../common/enums/hub-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { CreateHubDto } from './dto/create-hub.dto';
import { DecideHubDto } from './dto/decide-hub.dto';
import { HubAdminNoticeService } from './hub-admin-notice.service';
import { Hub } from './hub.entity';

@Injectable()
export class HubsService {
  constructor(
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    private readonly usersService: UsersService,
    private readonly adminNotice: HubAdminNoticeService,
  ) {}

  async create(user: User, dto: CreateHubDto) {
    this.assertActiveAccount(user);
    if (user.hubId) {
      throw new ConflictException(
        'Ya registraste una central. Espera la aprobación.',
      );
    }
    const existing = await this.hubs.findOne({
      where: { createdByUserId: user.id },
    });
    if (existing) {
      throw new ConflictException(
        'Ya registraste una central. Espera la aprobación.',
      );
    }
    const hub = this.hubs.create({
      name: dto.name.trim(),
      type: dto.type,
      address: dto.address.trim(),
      latitude: dto.latitude,
      longitude: dto.longitude,
      contactPhone: dto.contactPhone,
      contactEmail: dto.contactEmail ?? null,
      status: HubStatus.PENDING_APPROVAL,
      rejectionReason: null,
      createdByUserId: user.id,
    });
    const saved = await this.hubs.save(hub);
    user.hubId = saved.id;
    await this.usersService.save(user);
    this.adminNotice.notifyPendingApproval(saved);
    return this.toPublicHub(saved);
  }

  async findMine(user: User) {
    this.assertActiveAccount(user);
    if (!user.hubId) {
      throw new NotFoundException('No has registrado una central.');
    }
    const hub = await this.hubs.findOne({ where: { id: user.hubId } });
    if (!hub) {
      throw new NotFoundException('No has registrado una central.');
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

  async decide(hubId: string, dto: DecideHubDto) {
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    if (hub.status !== HubStatus.PENDING_APPROVAL) {
      throw new ConflictException('Esta central ya fue aprobada o rechazada.');
    }
    if (dto.status === HubStatus.REJECTED) {
      const reason = dto.reason?.trim();
      if (!reason) {
        throw new BadRequestException('El rechazo debe incluir un motivo.');
      }
      hub.status = HubStatus.REJECTED;
      hub.rejectionReason = reason;
    } else {
      hub.status = HubStatus.APPROVED;
      hub.rejectionReason = null;
    }
    const saved = await this.hubs.save(hub);
    this.adminNotice.notifyDecision(saved);
    return this.toPublicHub(saved);
  }

  findById(id: string): Promise<Hub | null> {
    return this.hubs.findOne({ where: { id } });
  }

  async requireApproved(id: string): Promise<Hub> {
    const hub = await this.findById(id);
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    if (hub.status !== HubStatus.APPROVED) {
      throw new ForbiddenException(
        'La central debe estar aprobada para operar.',
      );
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
      rejectionReason: hub.rejectionReason,
      createdAt: hub.createdAt,
    };
  }

  private assertActiveAccount(user: User): void {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar la central.',
      );
    }
  }
}
