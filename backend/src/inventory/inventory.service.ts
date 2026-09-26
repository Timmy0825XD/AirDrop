import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { UpdateInventoryItemDto } from './dto/update-inventory-item.dto';
import { InventoryItem } from './inventory-item.entity';

@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryItem)
    private readonly items: Repository<InventoryItem>,
    private readonly hubsService: HubsService,
  ) {}

  async create(user: User, dto: CreateInventoryItemDto) {
    const hub = await this.requireDispatcherHub(user);
    const item = this.items.create({
      hubId: hub.id,
      name: dto.name,
      quantity: dto.quantity,
      lot: dto.lot,
      expirationDate: dto.expirationDate,
      requiresColdChain: dto.requiresColdChain,
      saleType: dto.saleType,
    });
    const saved = await this.items.save(item);
    return this.toPublicItem(saved);
  }

  async list(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const rows = await this.items.find({
      where: { hubId: hub.id },
      order: { name: 'ASC', expirationDate: 'ASC' },
    });
    return rows.map((row) => this.toPublicItem(row));
  }

  async update(user: User, id: string, dto: UpdateInventoryItemDto) {
    if (
      dto.name === undefined &&
      dto.quantity === undefined &&
      dto.lot === undefined &&
      dto.expirationDate === undefined &&
      dto.requiresColdChain === undefined &&
      dto.saleType === undefined
    ) {
      throw new BadRequestException(
        'Debes enviar al menos un campo para actualizar.',
      );
    }
    const item = await this.requireOwnItem(user, id);
    if (dto.name !== undefined) {
      item.name = dto.name;
    }
    if (dto.quantity !== undefined) {
      item.quantity = dto.quantity;
    }
    if (dto.lot !== undefined) {
      item.lot = dto.lot;
    }
    if (dto.expirationDate !== undefined) {
      item.expirationDate = dto.expirationDate;
    }
    if (dto.requiresColdChain !== undefined) {
      item.requiresColdChain = dto.requiresColdChain;
    }
    if (dto.saleType !== undefined) {
      item.saleType = dto.saleType;
    }
    const saved = await this.items.save(item);
    return this.toPublicItem(saved);
  }

  async remove(user: User, id: string) {
    const item = await this.requireOwnItem(user, id);
    await this.items.remove(item);
  }

  toPublicItem(item: InventoryItem) {
    return {
      id: item.id,
      hubId: item.hubId,
      name: item.name,
      quantity: item.quantity,
      lot: item.lot,
      expirationDate: item.expirationDate,
      requiresColdChain: item.requiresColdChain,
      saleType: item.saleType,
      createdAt: item.createdAt,
    };
  }

  private async requireDispatcherHub(user: User) {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar inventario.',
      );
    }
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException(
        'Solo el despachador gestiona el inventario de su central.',
      );
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new ForbiddenException(
        'Debes tener una central asignada para gestionar inventario.',
      );
    }
    return this.hubsService.requireActive(hubIds[0]);
  }

  private async requireOwnItem(user: User, id: string) {
    const hub = await this.requireDispatcherHub(user);
    const item = await this.items.findOne({ where: { id } });
    if (!item || item.hubId !== hub.id) {
      throw new NotFoundException('El ítem de inventario no existe.');
    }
    return item;
  }
}
