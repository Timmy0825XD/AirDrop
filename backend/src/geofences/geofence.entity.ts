import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';

@Entity({ name: 'geofences' })
export class Geofence {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.geofenceName })
  name: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.reason })
  reason: string;

  @Index({ spatial: true })
  @Column({
    type: 'geometry',
    spatialFeatureType: 'Polygon',
    srid: 4326,
  })
  polygon: string;

  @Index()
  @Column({ type: 'uuid' })
  createdByUserId: string;

  /**
   * RF-36: una geovalla temporal de la consola vence en esta hora simulada.
   * `null` es una geovalla del operador, que no vence.
   */
  @Index()
  @Column({ type: 'timestamptz', nullable: true })
  expiresAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
