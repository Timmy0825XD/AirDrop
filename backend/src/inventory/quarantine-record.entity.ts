import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { QuarantineReason } from '../common/enums/quarantine-reason.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../common/field-limits';

/**
 * Insumo devuelto que no vuelve al estante: no se dispensa ni se traslada
 * otra vez. Una fila por pedido.
 */
@Entity({ name: 'quarantine_records' })
export class QuarantineRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  @Index()
  @Column({ type: 'uuid' })
  hubId: string;

  @Column({ type: 'varchar', length: FIELD_LIMITS.medicationName })
  medicationName: string;

  @Column({ type: 'enum', enum: SaleType, enumName: 'sale_type' })
  saleType: SaleType;

  @Column({ type: 'varchar', length: FIELD_LIMITS.lotCode })
  lot: string;

  @Column({ type: 'date' })
  expirationDate: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({
    type: 'enum',
    enum: QuarantineReason,
    enumName: 'quarantine_reason',
  })
  reason: QuarantineReason;

  @Index()
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
