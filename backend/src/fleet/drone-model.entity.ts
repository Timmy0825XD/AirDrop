import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { DroneKind } from '../common/enums/drone-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

@Entity({ name: 'drone_models' })
export class DroneModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: FIELD_LIMITS.droneModelCode })
  code: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.droneModelName })
  name: string;

  /** RF-49: Colibrí, Garza o Cóndor. */
  @Column({
    type: 'enum',
    enum: DroneKind,
    enumName: 'drone_kind',
    default: DroneKind.BALANCED,
  })
  kind: DroneKind;

  /** Techo de servicio sobre el nivel del mar, en metros (RF-46). */
  @Column({ type: 'smallint', default: 4000 })
  ceilingM: number;

  @Column({
    type: 'numeric',
    precision: 3,
    scale: 1,
    default: 4,
    transformer: NUMERIC_TRANSFORMER,
  })
  verticalSpeedMs: number;

  /** Masa máxima al despegue: entra en la energía de subida (RF-46). */
  @Column({
    type: 'numeric',
    precision: 4,
    scale: 1,
    default: 18,
    transformer: NUMERIC_TRANSFORMER,
  })
  mtowKg: number;

  @Column({ type: 'smallint', default: 1500 })
  batteryWh: number;

  /** Límite de viento sostenido y en ráfaga (RF-32). */
  @Column({
    type: 'numeric',
    precision: 3,
    scale: 1,
    default: 15,
    transformer: NUMERIC_TRANSFORMER,
  })
  windSustainedMs: number;

  @Column({
    type: 'numeric',
    precision: 3,
    scale: 1,
    default: 20,
    transformer: NUMERIC_TRANSFORMER,
  })
  windGustMs: number;

  @Column({
    type: 'numeric',
    precision: 5,
    scale: 1,
    transformer: NUMERIC_TRANSFORMER,
  })
  maxSpeedKmh: number;

  @Column({
    type: 'numeric',
    precision: 3,
    scale: 1,
    transformer: NUMERIC_TRANSFORMER,
  })
  maxPayloadKg: number;

  @Column({
    type: 'numeric',
    precision: 5,
    scale: 1,
    transformer: NUMERIC_TRANSFORMER,
  })
  maxRangeKm: number;
}
