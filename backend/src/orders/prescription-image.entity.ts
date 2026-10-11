import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';

/** La fórmula no se escribe en logs. El archivo vive en el bucket privado. */
@Entity({ name: 'prescription_images' })
export class PrescriptionImage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  /** Clave dentro del bucket `prescriptions`. No es una URL. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.prescriptionObjectKey })
  objectKey: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.prescriptionMime })
  mime: string;
}
