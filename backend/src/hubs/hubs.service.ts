import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { Drone } from '../fleet/drone.entity';
import { Order } from '../orders/order.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { UpdateHubDto } from './dto/update-hub.dto';
import { Hub } from './hub.entity';
import {
  HUB_HAS_LIVE_ORDERS,
  HUB_INSIDE_GEOFENCE,
  LIVE_ORDER_STATUSES,
  REASSIGNED_HERE,
  assertHubPatch,
  movesLocation,
} from './hubs.rules';

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

  /**
   * El administrador corrige una central. La ubicación solo se mueve si no
   * hay vuelos ni pedidos en curso que dependan de ella, y nunca dentro de
   * una geovalla.
   */
  async update(user: User, hubId: string, dto: UpdateHubDto) {
    this.assertActiveAdmin(user, 'Solo el administrador edita centrales.');
    assertHubPatch(dto);
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    if (movesLocation(hub, dto)) {
      await this.assertCanMove(hub.id);
      await this.assertOutsideGeofences(
        dto.longitude as number,
        dto.latitude as number,
      );
      hub.latitude = dto.latitude as number;
      hub.longitude = dto.longitude as number;
    }
    if (dto.name !== undefined) hub.name = dto.name.trim();
    if (dto.type !== undefined) hub.type = dto.type;
    if (dto.address !== undefined) hub.address = dto.address.trim();
    if (dto.contactPhone !== undefined) hub.contactPhone = dto.contactPhone;
    if (dto.contactEmail !== undefined) hub.contactEmail = dto.contactEmail;
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

  private async assertCanMove(hubId: string): Promise<void> {
    const manager = this.hubs.manager;
    const [liveOrders, flyingDrones] = await Promise.all([
      manager.exists(Order, {
        where: [
          { originHubId: hubId, status: In(LIVE_ORDER_STATUSES) },
          { destinationHubId: hubId, status: In(LIVE_ORDER_STATUSES) },
          { originHubId: hubId, ...REASSIGNED_HERE },
        ],
      }),
      manager.exists(Drone, {
        where: { hubId, status: DroneStatus.IN_MISSION },
      }),
    ]);
    if (liveOrders || flyingDrones) {
      throw new ConflictException(HUB_HAS_LIVE_ORDERS);
    }
  }

  private async assertOutsideGeofences(
    longitude: number,
    latitude: number,
  ): Promise<void> {
    const rows = await this.hubs.manager.query<Array<{ inside: boolean }>>(
      `SELECT EXISTS (
         SELECT 1 FROM geofences
         WHERE ST_Contains(polygon, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ) AS inside`,
      [longitude, latitude],
    );
    if (rows[0]?.inside) {
      throw new BadRequestException(HUB_INSIDE_GEOFENCE);
    }
  }

  private assertActiveAdmin(
    user: User,
    message = 'Solo el administrador crea centrales.',
  ): void {
    this.assertActiveAccount(user);
    if (user.role !== UserRole.ADMIN) {
      throw new ForbiddenException(message);
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
