import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';
import { GeofenceClass } from '../common/enums/geofence-class.enum';
import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { OperationalCategory } from '../common/enums/operational-category.enum';

/**
 * RF-21: toda geovalla, legal (RF-43), operativa o temporal (RF-36). La
 * clase dice quién la gestiona y qué datos lleva; la forma, cómo se edita.
 * El polígono siempre está: es lo que rodea el planificador.
 */
@Entity({ name: 'geofences' })
export class Geofence {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({
    type: 'enum',
    enum: GeofenceClass,
    enumName: 'geofence_class',
    default: GeofenceClass.OPERATIONAL,
  })
  class: GeofenceClass;

  @Column({
    type: 'enum',
    enum: GeofenceShape,
    enumName: 'geofence_shape',
    default: GeofenceShape.POLYGON,
  })
  shape: GeofenceShape;

  @Column({ type: 'varchar', length: FIELD_LIMITS.geofenceName })
  name: string;

  /** Operativa y temporal. Una zona legal no lleva motivo: lleva base legal. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  reason: string | null;

  @Column({
    type: 'enum',
    enum: OperationalCategory,
    enumName: 'operational_category',
    nullable: true,
  })
  category: OperationalCategory | null;

  /** Solo un círculo. */
  @Column({ type: 'numeric', precision: 9, scale: 6, nullable: true })
  centerLatitude: string | null;

  @Column({ type: 'numeric', precision: 9, scale: 6, nullable: true })
  centerLongitude: string | null;

  /** Solo un círculo: de 50 m a 5 km. */
  @Column({ type: 'int', nullable: true })
  radiusM: number | null;

  @Index({ spatial: true })
  @Column({
    type: 'geometry',
    spatialFeatureType: 'Polygon',
    srid: 4326,
  })
  polygon: string;

  /** Zona legal: código estable (`skvp`, `cai-hurtado`). */
  @Index({ unique: true, where: '"code" IS NOT NULL' })
  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.geofenceCode,
    nullable: true,
  })
  code: string | null;

  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.legalReference,
    nullable: true,
  })
  legalBasis: string | null;

  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.legalReference,
    nullable: true,
  })
  source: string | null;

  /** Una zona legal desactivada no bloquea rutas, pero no se borra. */
  @Index()
  @Column({ type: 'boolean', default: true })
  active: boolean;

  /** `null` en las zonas legales que trae el sistema. */
  @Index()
  @Column({ type: 'uuid', nullable: true })
  createdByUserId: string | null;

  @Column({ type: 'uuid', nullable: true })
  updatedByUserId: string | null;

  /**
   * Hora simulada en que deja de regir: el vencimiento de una temporal
   * (RF-36) o la vigencia de una operativa. `null` no vence.
   */
  @Index()
  @Column({ type: 'timestamptz', nullable: true })
  expiresAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
