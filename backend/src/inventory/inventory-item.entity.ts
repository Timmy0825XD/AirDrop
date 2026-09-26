import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { SaleType } from '../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { Hub } from '../hubs/hub.entity';

@Entity({ name: 'inventory_items' })
export class InventoryItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  hubId: string;

  @ManyToOne(() => Hub, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'hubId' })
  hub: Hub;

  @Column({ type: 'varchar', length: FIELD_LIMITS.medicationName })
  name: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'varchar', length: FIELD_LIMITS.lotCode })
  lot: string;

  @Column({ type: 'date' })
  expirationDate: string;

  @Column({ type: 'boolean' })
  requiresColdChain: boolean;

  @Column({ type: 'enum', enum: SaleType, enumName: 'sale_type' })
  saleType: SaleType;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
