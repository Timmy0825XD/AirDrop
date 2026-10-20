import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Estado del código de un pedido. El código no se guarda: se deriva del pedido
 * (ver `deliveryCodeFor`), así que aquí solo queda si ya se usó y cuántos
 * intentos fallidos lleva.
 */
@Entity({ name: 'delivery_codes' })
export class DeliveryCode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  @Column({ type: 'timestamptz', nullable: true })
  usedAt: Date | null;

  /** Códigos equivocados. Con 5 el pedido queda bloqueado. */
  @Column({ type: 'int', default: 0 })
  attempts: number;
}
