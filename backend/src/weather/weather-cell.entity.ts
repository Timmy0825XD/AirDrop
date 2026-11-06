import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';
import { WeatherKind } from '../common/enums/weather-kind.enum';

/** RF-32: una celda de clima simulado, un círculo con duración. */
@Entity({ name: 'weather_cells' })
export class WeatherCell {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: WeatherKind, enumName: 'weather_kind' })
  kind: WeatherKind;

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

  @Column({
    type: 'numeric',
    precision: 5,
    scale: 2,
    transformer: NUMERIC_TRANSFORMER,
  })
  radiusKm: number;

  @Column({
    type: 'numeric',
    precision: 4,
    scale: 1,
    nullable: true,
    transformer: NUMERIC_TRANSFORMER,
  })
  windSpeedMs: number | null;

  @Column({
    type: 'numeric',
    precision: 4,
    scale: 1,
    nullable: true,
    transformer: NUMERIC_TRANSFORMER,
  })
  windGustMs: number | null;

  @Column({ type: 'smallint', nullable: true })
  windFromDeg: number | null;

  @Column({ type: 'timestamptz' })
  startsAt: Date;

  @Index()
  @Column({ type: 'timestamptz' })
  endsAt: Date;

  @Column({ type: 'uuid' })
  createdByUserId: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
