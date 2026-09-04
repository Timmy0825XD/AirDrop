import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { CHAR_TRANSFORMER } from '../common/column-transformers';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { OneTimeCode } from '../auth/one-time-code.entity';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.fullName })
  fullName: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: FIELD_LIMITS.email, nullable: true })
  email: string | null;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: FIELD_LIMITS.phone, nullable: true })
  phone: string | null;

  @Column({
    type: 'char',
    length: FIELD_LIMITS.bcryptHash,
    transformer: CHAR_TRANSFORMER,
  })
  passwordHash: string;

  @Index()
  @Column({ type: 'enum', enum: UserRole, enumName: 'user_role' })
  role: UserRole;

  @Index()
  @Column({
    type: 'enum',
    enum: UserStatus,
    enumName: 'user_status',
    default: UserStatus.UNVERIFIED,
  })
  status: UserStatus;

  @Column({ type: 'timestamptz' })
  consentAcceptedAt: Date;

  @Column({ type: 'smallint', default: 0 })
  failedLoginCount: number;

  @Column({ type: 'timestamptz', nullable: true })
  lockedUntil: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;

  @OneToMany(() => OneTimeCode, (code) => code.user)
  oneTimeCodes: OneTimeCode[];
}
