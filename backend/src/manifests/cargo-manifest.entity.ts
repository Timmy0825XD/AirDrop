import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DroneKind } from '../common/enums/drone-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

/** Un ítem del manifiesto: lo que va en el compartimento, sin el paciente. */
export type ManifestItem = {
  medicationName: string;
  lot: string;
  expiresOn: string;
  quantity: number;
};

/**
 * RF-47: manifiesto de carga numerado por operación (RAC 100.440(a)(21)).
 * Se emite al confirmar la carga y no se edita: si la carga cambia, se anula
 * y se emite otro con otro número. No lleva datos del paciente.
 */
@Entity({ name: 'cargo_manifests' })
@Index(['year', 'sequence'], { unique: true })
export class CargoManifest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** `MAN-2026-000123`. */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: FIELD_LIMITS.manifestNumber })
  number: string;

  @Column({ type: 'smallint' })
  year: number;

  @Column({ type: 'int' })
  sequence: number;

  @Index()
  @Column({ type: 'uuid' })
  orderId: string;

  @Index()
  @Column({ type: 'uuid' })
  droneId: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.droneIdentifier })
  droneIdentifier: string;

  @Column({ type: 'enum', enum: DroneKind, enumName: 'drone_kind' })
  droneKind: DroneKind;

  @Index()
  @Column({ type: 'uuid' })
  originHubId: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.hubName })
  originName: string;

  /** Punto de entrega o ESE. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.hubName })
  destinationName: string;

  @Column({ type: 'jsonb' })
  items: ManifestItem[];

  /** Peso de la carga, en kg. */
  @Column({
    type: 'numeric',
    precision: 6,
    scale: 3,
    transformer: NUMERIC_TRANSFORMER,
  })
  payloadKg: number;

  /** El compartimento de frío, si va instalado (RF-49). */
  @Column({
    type: 'numeric',
    precision: 4,
    scale: 2,
    transformer: NUMERIC_TRANSFORMER,
    nullable: true,
  })
  coldCompartmentKg: number | null;

  /** El rango exigido si la carga es fría (`2–8 °C`). */
  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.coldRange,
    nullable: true,
  })
  coldRange: string | null;

  /** El despachador que confirmó la carga; nulo si fue el automático (RF-37). */
  @Column({ type: 'uuid', nullable: true })
  authorizedByUserId: string | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.fullName })
  authorizedByName: string;

  /** Hora simulada de la confirmación. */
  @Column({ type: 'timestamptz' })
  issuedAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  voidedAt: Date | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  voidReason: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
