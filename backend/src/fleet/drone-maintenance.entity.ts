import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { Drone } from './drone.entity';

/**
 * Historial de taller de un dron: cada vez que sale de la flota (mantenimiento
 * o fuera de servicio) y cuándo volvió. Un dron tiene a lo sumo un periodo
 * abierto (`closedAt` nulo).
 */
@Entity({ name: 'drone_maintenances' })
@Index(['droneId', 'startedAt'])
export class DroneMaintenance {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  droneId: string;

  @ManyToOne(() => Drone, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'droneId' })
  drone: Drone;

  @Column({
    type: 'enum',
    enum: DroneMaintenanceKind,
    enumName: 'drone_maintenance_kind',
  })
  kind: DroneMaintenanceKind;

  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  reason: string | null;

  /** Fin estimado (AAAA-MM-DD). Fuera de servicio no lo tiene. */
  @Column({ type: 'date', nullable: true })
  estimatedEndDate: string | null;

  /** Vuelos que llevaba desde el mantenimiento anterior al entrar al taller. */
  @Column({ type: 'int' })
  flightsAtStart: number;

  @Column({ type: 'uuid' })
  openedByUserId: string;

  @CreateDateColumn({ type: 'timestamptz' })
  startedAt: Date;

  @Index()
  @Column({ type: 'timestamptz', nullable: true })
  closedAt: Date | null;

  @Column({ type: 'uuid', nullable: true })
  closedByUserId: string | null;
}
