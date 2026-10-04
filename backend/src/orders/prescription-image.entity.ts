import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { FIELD_LIMITS } from '../common/field-limits';

/** La fórmula no se escribe en logs. En esta rama queda guardada con el pedido. */
@Entity({ name: 'prescription_images' })
export class PrescriptionImage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  @Column({ type: 'bytea' })
  content: Buffer;

  @Column({ type: 'varchar', length: FIELD_LIMITS.prescriptionMime })
  mime: string;
}
