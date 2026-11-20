import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  type Relation,
} from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';
import { Geofence } from './geofence.entity';

export enum GeofenceChangeAction {
  CREATED = 'created',
  UPDATED = 'updated',
  DEACTIVATED = 'deactivated',
  REACTIVATED = 'reactivated',
}

/** Un campo que cambió: valor de antes y de después. */
export type FieldChange = { from: unknown; to: unknown };

/**
 * RU-36 y CU-52: el historial de una zona legal. Quién, cuándo, qué hizo,
 * por qué y qué campos cambiaron. Ningún endpoint lo edita.
 */
@Entity({ name: 'geofence_changes' })
export class GeofenceChange {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  geofenceId: string;

  @ManyToOne(() => Geofence, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'geofenceId' })
  geofence: Relation<Geofence>;

  @Index()
  @Column({ type: 'uuid' })
  userId: string;

  @Column({
    type: 'enum',
    enum: GeofenceChangeAction,
    enumName: 'geofence_change_action',
  })
  action: GeofenceChangeAction;

  /** Obligatorio al editar, desactivar o reactivar; el alta no lo pide. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  reason: string | null;

  @Column({ type: 'jsonb', default: () => `'{}'` })
  changes: Record<string, FieldChange>;

  @Index()
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
