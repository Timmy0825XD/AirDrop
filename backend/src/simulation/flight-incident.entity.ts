import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { IncidentOutcome } from '../common/enums/incident-outcome.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../common/field-limits';
import { NUMERIC_TRANSFORMER } from '../common/numeric.transformer';

export type IncidentSeverity = 'minor' | 'major';

/**
 * RF-34 y CU-32: un incidente en vuelo, con el protocolo que eligieron las
 * reglas y en qué quedó. La misión fallida se reconoce por él (RF-35).
 */
@Entity({ name: 'flight_incidents' })
export class FlightIncident {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  orderId: string;

  @Index()
  @Column({ type: 'uuid' })
  droneId: string;

  /** Central del dron: a ella vuelve y desde ella sale el rescate. */
  @Column({ type: 'uuid' })
  hubId: string;

  @Column({ type: 'enum', enum: IncidentKind, enumName: 'incident_kind' })
  kind: IncidentKind;

  @Column({ type: 'varchar', length: 10 })
  severity: IncidentSeverity;

  @Column({ type: 'enum', enum: RouteLeg, enumName: 'route_leg' })
  leg: RouteLeg;

  @Column({
    type: 'enum',
    enum: ContingencyProtocol,
    enumName: 'contingency_protocol',
  })
  protocol: ContingencyProtocol;

  @Index()
  @Column({
    type: 'enum',
    enum: IncidentOutcome,
    enumName: 'incident_outcome',
  })
  outcome: IncidentOutcome;

  @Column({ type: 'double precision' })
  latitude: number;

  @Column({ type: 'double precision' })
  longitude: number;

  @Column({
    type: 'numeric',
    precision: 4,
    scale: 1,
    transformer: NUMERIC_TRANSFORMER,
  })
  batteryPercent: number;

  /** Aterrizaje de emergencia: dónde baja el dron. */
  @Column({ type: 'double precision', nullable: true })
  landingLatitude: number | null;

  @Column({ type: 'double precision', nullable: true })
  landingLongitude: number | null;

  /** Hora simulada en que el equipo de rescate llega con el dron a la central. */
  @Column({ type: 'timestamptz', nullable: true })
  rescueDueAt: Date | null;

  /**
   * El paquete que llevaba, copiado al momento del incidente: si la urgencia
   * se vuelve a despachar, el pedido cambia de lote (RF-35). `null`: iba vacío.
   */
  @Column({
    type: 'varchar',
    length: FIELD_LIMITS.medicationName,
    nullable: true,
  })
  packageMedication: string | null;

  @Column({
    type: 'enum',
    enum: SaleType,
    enumName: 'sale_type',
    nullable: true,
  })
  packageSaleType: SaleType | null;

  @Column({ type: 'int', nullable: true })
  packageQuantity: number | null;

  @Column({ type: 'varchar', length: FIELD_LIMITS.lotCode, nullable: true })
  packageLot: string | null;

  @Column({ type: 'date', nullable: true })
  packageLotExpiresOn: string | null;

  /** Hora simulada del incidente (`SimTimeSubscriber`). */
  @CreateDateColumn({ type: 'timestamptz' })
  occurredAt: Date;

  /** Siguió, llegó a la central o lo rescataron. */
  @Column({ type: 'timestamptz', nullable: true })
  resolvedAt: Date | null;
}
