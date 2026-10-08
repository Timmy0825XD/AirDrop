import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

@Entity({ name: 'mission_routes' })
export class MissionRoute {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  @Column({ type: 'enum', enum: RouteLeg, enumName: 'route_leg' })
  leg: RouteLeg;

  @Column({
    type: 'numeric',
    precision: 5,
    scale: 1,
    transformer: NUMERIC_TRANSFORMER,
  })
  altitudeM: number;

  @Column({
    type: 'numeric',
    precision: 6,
    scale: 2,
    transformer: NUMERIC_TRANSFORMER,
  })
  distanceKm: number;

  @Index({ spatial: true })
  @Column({
    type: 'geometry',
    spatialFeatureType: 'LineString',
    srid: 4326,
  })
  path: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
