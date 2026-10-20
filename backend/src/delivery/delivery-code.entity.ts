import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { CHAR_TRANSFORMER } from '../common/column-transformers';
import { FIELD_LIMITS } from '../common/field-limits';

/** Código de un solo uso para recibir el pedido. Solo se guarda su hash. */
@Entity({ name: 'delivery_codes' })
export class DeliveryCode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  @Column({
    type: 'char',
    length: FIELD_LIMITS.sha256Hex,
    transformer: CHAR_TRANSFORMER,
  })
  codeHash: string;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  usedAt: Date | null;

  /** Códigos equivocados. No se reinicia al pedir un código nuevo. */
  @Column({ type: 'int', default: 0 })
  attempts: number;
}
