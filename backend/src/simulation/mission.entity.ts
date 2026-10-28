import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/** Resumen de la misión. Cada tick de 2 s se queda en Redis. */
@Entity({ name: 'missions' })
export class Mission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'uuid' })
  orderId: string;

  @Index()
  @Column({ type: 'uuid' })
  droneId: string;

  @Column({ type: 'timestamptz' })
  startedAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  landedAt: Date | null;

  /** El dron volvió a su central: cierra el tiempo en misión (RF-26). */
  @Column({ type: 'timestamptz', nullable: true })
  returnedAt: Date | null;

  @Column({ type: 'boolean', default: false })
  batteryAlert: boolean;

  @Column({ type: 'boolean', default: false })
  failureAlert: boolean;
}
