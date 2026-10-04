import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderPriority } from '../common/enums/order-priority.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';

@Entity({ name: 'orders' })
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'enum', enum: MissionType, enumName: 'mission_type' })
  missionType: MissionType;

  @Column({
    type: 'enum',
    enum: DestinationKind,
    enumName: 'destination_kind',
  })
  destinationKind: DestinationKind;

  @Index()
  @Column({ type: 'enum', enum: OrderStatus, enumName: 'order_status' })
  status: OrderStatus;

  @Column({ type: 'enum', enum: OrderPriority, enumName: 'order_priority' })
  priority: OrderPriority;

  @Column({ type: 'varchar', length: FIELD_LIMITS.medicationName })
  medicationName: string;

  @Column({ type: 'enum', enum: SaleType, enumName: 'sale_type' })
  saleType: SaleType;

  @Column({ type: 'boolean' })
  requiresColdChain: boolean;

  @Column({ type: 'int' })
  quantity: number;

  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.orderDescription,
    nullable: true,
  })
  description: string | null;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  requesterId: string | null;

  @Index()
  @Column({ type: 'uuid' })
  createdByUserId: string;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  destinationHubId: string | null;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  originHubId: string | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.address })
  address: string;

  @Column({
    type: 'numeric',
    precision: 9,
    scale: 6,
    transformer: NUMERIC_TRANSFORMER,
    nullable: true,
  })
  latitude: number | null;

  @Column({
    type: 'numeric',
    precision: 9,
    scale: 6,
    transformer: NUMERIC_TRANSFORMER,
    nullable: true,
  })
  longitude: number | null;

  @Column({ type: 'uuid', nullable: true })
  droneId: string | null;

  /** Motivo del rechazo. Vacío mientras el pedido sigue en recibido. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  statusReason: string | null;

  @Index()
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
