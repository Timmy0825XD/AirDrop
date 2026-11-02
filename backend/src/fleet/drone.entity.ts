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
import { DroneStatus } from '../common/enums/drone-status.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';
import { Hub } from '../hubs/hub.entity';
import { DroneModel } from './drone-model.entity';

@Entity({ name: 'drones' })
export class Drone {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: FIELD_LIMITS.droneIdentifier })
  identifier: string;

  @Column({ type: 'uuid' })
  droneModelId: string;

  @ManyToOne(() => DroneModel, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'droneModelId' })
  droneModel: DroneModel;

  @Index()
  @Column({ type: 'uuid' })
  hubId: string;

  @ManyToOne(() => Hub, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'hubId' })
  hub: Hub;

  @Index()
  @Column({
    type: 'enum',
    enum: DroneStatus,
    enumName: 'drone_status',
    default: DroneStatus.AVAILABLE,
  })
  status: DroneStatus;

  /** Batería al aterrizar la última vez; en tierra recarga (`batteryNow`). */
  @Column({
    type: 'numeric',
    precision: 4,
    scale: 1,
    default: 100,
    transformer: NUMERIC_TRANSFORMER,
  })
  batteryPercent: number;

  /** Desde cuándo recarga. `null`: nunca ha volado, está llena. */
  @Column({ type: 'timestamptz', nullable: true })
  batteryUpdatedAt: Date | null;

  /** Fin del último vuelo: la flota rota del que lleva más tiempo en tierra. */
  @Column({ type: 'timestamptz', nullable: true })
  lastFlightEndedAt: Date | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  maintenanceReason: string | null;

  @Column({ type: 'date', nullable: true })
  maintenanceUntil: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
