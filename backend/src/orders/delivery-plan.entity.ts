import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import { ScheduleKind } from '../common/enums/schedule-kind.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

@Entity({ name: 'delivery_plans' })
export class DeliveryPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Solo los planes creados con la frecuencia anterior (8 semanas, todo el
   * día). Los demás usan la regla de calendario de abajo.
   */
  @Column({
    type: 'enum',
    enum: PlanFrequency,
    enumName: 'plan_frequency',
    nullable: true,
  })
  frequency: PlanFrequency | null;

  /** RU-30: regla de calendario. Nula en los planes anteriores a ella. */
  @Column({
    type: 'enum',
    enum: ScheduleKind,
    enumName: 'schedule_kind',
    nullable: true,
  })
  scheduleKind: ScheduleKind | null;

  /** 1 = lunes … 7 = domingo. */
  @Column({ type: 'smallint', array: true, nullable: true })
  daysOfWeek: number[] | null;

  @Column({ type: 'smallint', nullable: true })
  everyWeeks: number | null;

  @Column({ type: 'smallint', nullable: true })
  dayOfMonth: number | null;

  @Column({ type: 'date', array: true, nullable: true })
  scheduleDates: string[] | null;

  /** Fin por número de entregas, en vez de por fecha. */
  @Column({ type: 'smallint', nullable: true })
  occurrenceCount: number | null;

  /** Inicio de la franja de 1 hora (`HH:00`). Nula: todo el horario operativo. */
  @Column({ type: 'varchar', length: 5, nullable: true })
  deliveryTime: string | null;

  /** Bajo fórmula: el plan no pasa de esta fecha. */
  @Column({ type: 'date', nullable: true })
  prescriptionValidUntil: string | null;

  @Index()
  @Column({ type: 'enum', enum: PlanStatus, enumName: 'plan_status' })
  status: PlanStatus;

  @Column({ type: 'varchar', length: FIELD_LIMITS.medicationName })
  medicationName: string;

  @Column({ type: 'enum', enum: SaleType, enumName: 'sale_type' })
  saleType: SaleType;

  @Column({ type: 'boolean' })
  requiresColdChain: boolean;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'date' })
  startDate: string;

  /** Día siguiente al último que cubre el plan (fin exclusivo). */
  @Column({ type: 'date' })
  windowEndsOn: string;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  requesterId: string | null;

  @Index()
  @Column({ type: 'uuid' })
  createdByUserId: string;

  @Column({
    type: 'enum',
    enum: DestinationKind,
    enumName: 'destination_kind',
  })
  destinationKind: DestinationKind;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  destinationHubId: string | null;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  originHubId: string | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.address })
  address: string;

  @Column({
    type: 'numeric',
    precision: 9,
    scale: 6,
    transformer: NUMERIC_TRANSFORMER,
    nullable: true,
  })
  latitude: number | null;

  @Column({
    type: 'numeric',
    precision: 9,
    scale: 6,
    transformer: NUMERIC_TRANSFORMER,
    nullable: true,
  })
  longitude: number | null;

  @Index()
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
