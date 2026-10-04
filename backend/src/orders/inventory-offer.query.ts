import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HubStatus } from '../common/enums/hub-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { todayInColombia } from './orders.rules';

export type CatalogRow = {
  name: string;
  saleType: SaleType;
  requiresColdChain: boolean;
  availableQuantity: number;
};

@Injectable()
export class InventoryOfferQuery {
  constructor(
    @InjectRepository(InventoryItem)
    private readonly items: Repository<InventoryItem>,
  ) {}

  catalog(hubId?: string): Promise<CatalogRow[]> {
    return this.grouped(hubId);
  }

  async offer(
    name: string,
    saleType: SaleType,
    hubId?: string,
  ): Promise<CatalogRow | null> {
    const rows = await this.grouped(hubId, name, saleType);
    return rows[0] ?? null;
  }

  async stockForHub(hubId: string): Promise<CatalogRow[]> {
    return this.grouped(hubId);
  }

  private async grouped(
    hubId?: string,
    name?: string,
    saleType?: SaleType,
  ): Promise<CatalogRow[]> {
    const query = this.items
      .createQueryBuilder('item')
      .innerJoin('item.hub', 'hub')
      .where('hub.status = :active', { active: HubStatus.ACTIVE })
      .andWhere('item.quantity > 0')
      .andWhere('item.expirationDate >= :today', { today: todayInColombia() })
      .andWhere('item.saleType != :special', {
        special: SaleType.SPECIAL_CONTROL,
      });
    if (hubId) {
      query.andWhere('item.hubId = :hubId', { hubId });
    }
    if (name) {
      query.andWhere('LOWER(item.name) = :name', {
        name: name.trim().toLowerCase(),
      });
    }
    if (saleType) {
      query.andWhere('item.saleType = :saleType', { saleType });
    }
    const rows = await query
      .select('MIN(item.name)', 'name')
      .addSelect('item.saleType', 'saleType')
      .addSelect('BOOL_OR(item.requiresColdChain)', 'requiresColdChain')
      .addSelect('SUM(item.quantity)', 'availableQuantity')
      .groupBy('LOWER(item.name)')
      .addGroupBy('item.saleType')
      .orderBy('MIN(item.name)', 'ASC')
      .getRawMany<{
        name: string;
        saleType: SaleType;
        requiresColdChain: boolean | string;
        availableQuantity: string | number;
      }>();
    return rows.map((row) => ({
      name: row.name,
      saleType: row.saleType,
      requiresColdChain:
        row.requiresColdChain === true || row.requiresColdChain === 'true',
      availableQuantity: Number(row.availableQuantity),
    }));
  }
}
