import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
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
