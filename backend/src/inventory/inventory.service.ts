import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
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
      expirationDate: dto.expirationDate,
      requiresColdChain: dto.requiresColdChain,
      requiresPrescription: dto.requiresPrescription,
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
      dto.expirationDate === undefined &&
      dto.requiresColdChain === undefined &&
      dto.requiresPrescription === undefined
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
    if (dto.expirationDate !== undefined) {
      item.expirationDate = dto.expirationDate;
    }
    if (dto.requiresColdChain !== undefined) {
      item.requiresColdChain = dto.requiresColdChain;
    }
    if (dto.requiresPrescription !== undefined) {
      item.requiresPrescription = dto.requiresPrescription;
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
      expirationDate: item.expirationDate,
      requiresColdChain: item.requiresColdChain,
      requiresPrescription: item.requiresPrescription,
      createdAt: item.createdAt,
    };
  }

  private async requireDispatcherHub(user: User) {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar inventario.',
      );
    }
    if (!user.hubId) {
      throw new ForbiddenException(
        'Debes registrar una central antes de gestionar inventario.',
      );
    }
    return this.hubsService.requireApproved(user.hubId);
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
