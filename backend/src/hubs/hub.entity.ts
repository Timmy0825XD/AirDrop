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
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';
import { User } from '../users/user.entity';

@Entity({ name: 'hubs' })
export class Hub {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.hubName })
  name: string;

  @Column({ type: 'enum', enum: HubType, enumName: 'hub_type' })
  type: HubType;

  @Column({ type: 'varchar', length: FIELD_LIMITS.address })
  address: string;

  @Column({
    type: 'numeric',
    precision: 9,
    scale: 6,
    transformer: NUMERIC_TRANSFORMER,
  })
  latitude: number;

  @Column({
    type: 'numeric',
    precision: 9,
    scale: 6,
    transformer: NUMERIC_TRANSFORMER,
  })
  longitude: number;

  @Column({ type: 'varchar', length: FIELD_LIMITS.phone })
  contactPhone: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.email, nullable: true })
  contactEmail: string | null;

  @Index()
  @Column({
    type: 'enum',
    enum: HubStatus,
    enumName: 'hub_status',
    default: HubStatus.PENDING_APPROVAL,
  })
  status: HubStatus;

  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  rejectionReason: string | null;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  createdByUserId: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'createdByUserId' })
  createdBy: User;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
