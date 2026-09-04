import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { CHAR_TRANSFORMER } from '../common/column-transformers';
import { OtpPurpose } from '../common/enums/otp-purpose.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { User } from '../users/user.entity';

@Entity({ name: 'one_time_codes' })
export class OneTimeCode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, (user) => user.oneTimeCodes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'enum', enum: OtpPurpose, enumName: 'otp_purpose' })
  purpose: OtpPurpose;

  @Column({
    type: 'char',
    length: FIELD_LIMITS.sha256Hex,
    transformer: CHAR_TRANSFORMER,
  })
  codeHash: string;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  consumedAt: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
