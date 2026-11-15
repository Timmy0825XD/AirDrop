import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { PrescriptionAccessPurpose } from '../common/enums/prescription-access-purpose.enum';
import { UserRole } from '../common/enums/user-role.enum';

/**
 * RF-51: cada apertura de una fórmula. Ningún endpoint la edita ni la borra
 * (Ley 1581, art. 17). Va en hora real, como el resto de la seguridad.
 */
@Entity({ name: 'prescription_access_logs' })
export class PrescriptionAccess {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  orderId: string;

  @Index()
  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'enum', enum: UserRole, enumName: 'user_role' })
  role: UserRole;

  @Column({
    type: 'enum',
    enum: PrescriptionAccessPurpose,
    enumName: 'prescription_access_purpose',
  })
  purpose: PrescriptionAccessPurpose;

  /** La hoja que abrió (0 = la primera), o `null` si listó los archivos. */
  @Column({ type: 'smallint', nullable: true })
  fileIndex: number | null;

  @Index()
  @Column({ type: 'timestamptz' })
  accessedAt: Date;
}
