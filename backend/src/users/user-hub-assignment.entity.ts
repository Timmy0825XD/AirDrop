import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Hub } from '../hubs/hub.entity';
import { User } from './user.entity';

@Entity({ name: 'user_hubs' })
@Unique(['userId', 'hubId'])
export class UserHubAssignment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  userId: string;

  @Index()
  @Column({ type: 'uuid' })
  hubId: string;

  @ManyToOne(() => User, (user) => user.hubAssignments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Hub, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'hubId' })
  hub: Hub;
}
