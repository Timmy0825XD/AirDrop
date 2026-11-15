import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

/**
 * RF-45: un lugar fijo de la red (puesto de salud o dronpuerto) donde el
 * paciente recoge con su código. No es una cuenta: lo crea el escenario
 * (`regional-network.ts`) y el administrador solo lo activa o lo desactiva.
 */
@Entity({ name: 'delivery_points' })
export class DeliveryPoint {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Código estable del escenario (`dp-patillal`). */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: FIELD_LIMITS.deliveryPointCode })
  code: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.hubName })
  name: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.municipality })
  municipality: string;

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

  /** Elevación del registro, en metros sobre el nivel del mar. */
  @Column({ type: 'smallint' })
  elevationM: number;

  /** El nodo que lo atiende; nulo si ese nodo no existe en la base. */
  @Index()
  @Column({ type: 'uuid', nullable: true })
  hubId: string | null;

  @Index()
  @Column({ type: 'boolean', default: true })
  active: boolean;

  /** RF-43: la zona coordinada donde está; su corredor es el pactado. */
  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.airspaceZoneCode,
    nullable: true,
  })
  coordinatedZoneCode: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
