import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';

/**
 * Un archivo de la fórmula (RU-25): un PDF o una de hasta 3 fotos. No se
 * escribe en logs. El archivo vive en el bucket privado.
 */
@Entity({ name: 'prescription_images' })
@Index('prescription_images_order_position', ['orderId', 'position'], {
  unique: true,
})
export class PrescriptionImage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  orderId: string;

  /** El orden de las hojas, desde 0. */
  @Column({ type: 'smallint', default: 0 })
  position: number;

  /** Clave dentro del bucket `prescriptions`. No es una URL. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.prescriptionObjectKey })
  objectKey: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.prescriptionMime })
  mime: string;
}
