import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderPriority } from '../common/enums/order-priority.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { ReturnOutcome } from '../common/enums/return-outcome.enum';
import { SaleType } from '../common/enums/sale-type.enum';

export type FallbackOption = {
  hubId: string;
  name: string;
  address: string;
  contactPhone: string;
  contactEmail: string | null;
  distanceKm: number;
};

@Entity({ name: 'orders' })
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'enum', enum: MissionType, enumName: 'mission_type' })
  missionType: MissionType;

  @Column({
    type: 'enum',
    enum: DestinationKind,
    enumName: 'destination_kind',
  })
  destinationKind: DestinationKind;

  @Index()
  @Column({ type: 'enum', enum: OrderStatus, enumName: 'order_status' })
  status: OrderStatus;

  @Column({ type: 'enum', enum: OrderPriority, enumName: 'order_priority' })
  priority: OrderPriority;

  @Column({ type: 'varchar', length: FIELD_LIMITS.medicationName })
  medicationName: string;

  @Column({ type: 'enum', enum: SaleType, enumName: 'sale_type' })
  saleType: SaleType;

  @Column({ type: 'boolean' })
  requiresColdChain: boolean;

  @Column({ type: 'int' })
  quantity: number;

  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.orderDescription,
    nullable: true,
  })
  description: string | null;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  requesterId: string | null;

  @Index()
  @Column({ type: 'uuid' })
  createdByUserId: string;

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
  @Column({ type: 'uuid', nullable: true })
  droneId: string | null;

  /** Lote elegido al autorizar. La cantidad no se descuenta hasta confirmar la carga. */
  @Index()
  @Column({ type: 'uuid', nullable: true })
  inventoryItemId: string | null;

  /** Cuándo se reservó el dron (RF-26: tiempo de respuesta). */
  @Column({ type: 'timestamptz', nullable: true })
  authorizedAt: Date | null;

  /** El reloj de vuelo no arranca antes de esta marca. */
  @Column({ type: 'timestamptz', nullable: true })
  loadConfirmedAt: Date | null;

  /**
   * Registro de salida: lote y vencimiento que se descontaron al confirmar
   * la carga. Sirven para reingresar o recibir el insumo aunque el ítem cambie.
   */
  @Column({ type: 'varchar', length: FIELD_LIMITS.lotCode, nullable: true })
  dispatchedLot: string | null;

  @Column({ type: 'date', nullable: true })
  dispatchedLotExpiresOn: string | null;

  /** Revisión del despachador de origen al recibir un paquete devuelto. */
  @Column({ type: 'timestamptz', nullable: true })
  returnCheckedAt: Date | null;

  @Column({
    type: 'enum',
    enum: ReturnOutcome,
    enumName: 'return_outcome',
    nullable: true,
  })
  returnOutcome: ReturnOutcome | null;

  /** Un traslado que la central de destino no recibió, y por qué. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  receiptRejectedReason: string | null;

  /** `false` si el sello llegó roto: el paquete vuelve directo a cuarentena. */
  @Column({ type: 'boolean', nullable: true })
  receiptSealIntact: boolean | null;

  /**
   * RF-17: la temperatura de la carga salió de 2–8 °C en ida, espera o
   * retorno. Con esta marca el insumo no reingresa al inventario.
   */
  @Column({ type: 'timestamptz', nullable: true })
  coldChainAlertAt: Date | null;

  /** Motivo del rechazo, o de cancelar el plan. */
  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  statusReason: string | null;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  planId: string | null;

  @Index()
  @Column({ type: 'date', nullable: true })
  scheduledFor: string | null;

  /** RU-30: inicio de la franja de entrega de un programado. */
  @Index()
  @Column({ type: 'timestamptz', nullable: true })
  scheduledAt: Date | null;

  /** Cierre de la franja: después de esto la entrega vence. */
  @Column({ type: 'timestamptz', nullable: true })
  windowEndsAt: Date | null;

  /** Quien recibe confirmó que estará (o la central, sola). */
  @Column({ type: 'timestamptz', nullable: true })
  confirmedAt: Date | null;

  /** Se mandó el aviso de T-24 h. */
  @Column({ type: 'timestamptz', nullable: true })
  remindedAt: Date | null;

  /** RF-18: alternativa cuando ningún dron de la central pudo salir. */
  @Column({
    type: 'enum',
    enum: FallbackKind,
    enumName: 'fallback_kind',
    nullable: true,
  })
  fallbackKind: FallbackKind | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.reason, nullable: true })
  fallbackReason: string | null;

  /** Centrales sugeridas en ese momento, de la más cercana a la más lejana. */
  @Column({ type: 'jsonb', nullable: true })
  fallbackOptions: FallbackOption[] | null;

  /** Central que no pudo despachar. Un pedido se reasigna una sola vez. */
  @Column({ type: 'uuid', nullable: true })
  reassignedFromHubId: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  reassignedAt: Date | null;

  /** Próximo intento automático de un programado sin dron libre. */
  @Index()
  @Column({ type: 'timestamptz', nullable: true })
  retryAfter: Date | null;

  /** El despachador verificó la fórmula; el reintento automático no la repite. */
  @Column({ type: 'timestamptz', nullable: true })
  prescriptionVerifiedAt: Date | null;

  @Index()
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
