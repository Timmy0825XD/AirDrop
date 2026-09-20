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

  @Column({ type: 'date' })
  expirationDate: string;

  @Column({ type: 'boolean' })
  requiresColdChain: boolean;

  @Column({ type: 'boolean' })
  requiresPrescription: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
