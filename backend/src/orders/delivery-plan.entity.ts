import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

@Entity({ name: 'delivery_plans' })
export class DeliveryPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: PlanFrequency, enumName: 'plan_frequency' })
  frequency: PlanFrequency;

  @Index()
  @Column({ type: 'enum', enum: PlanStatus, enumName: 'plan_status' })
  status: PlanStatus;

  @Column({ type: 'varchar', length: FIELD_LIMITS.medicationName })
  medicationName: string;

  @Column({ type: 'enum', enum: SaleType, enumName: 'sale_type' })
  saleType: SaleType;

  @Column({ type: 'boolean' })
  requiresColdChain: boolean;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'date' })
  startDate: string;

  /** Día en que empieza la ventana siguiente. Esta ventana no lo incluye. */
  @Column({ type: 'date' })
  windowEndsOn: string;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  requesterId: string | null;

  @Index()
  @Column({ type: 'uuid' })
  createdByUserId: string;

  @Column({
    type: 'enum',
    enum: DestinationKind,
    enumName: 'destination_kind',
  })
  destinationKind: DestinationKind;

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

  @Index()
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
