import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import {
  DataSource,
  EntityManager,
  In,
  IsNull,
  LessThanOrEqual,
} from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { IncidentOutcome } from '../common/enums/incident-outcome.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { QuarantineReason } from '../common/enums/quarantine-reason.enum';
import { ReturnOutcome } from '../common/enums/return-outcome.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneMaintenance } from '../fleet/drone-maintenance.entity';
import { Hub } from '../hubs/hub.entity';
import { QuarantineRecord } from '../inventory/quarantine-record.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { LngLat } from '../routing/routing.rules';
import { incidentSeverity, rescueDurationMs } from './contingency.rules';
import { FlightIncident } from './flight-incident.entity';
import { Mission } from './mission.entity';

/** Cada cuánto (en hora simulada) se mira si llegó algún rescate. */
const RESCUE_SWEEP_MS = 15_000;

export const RESCUE_MAINTENANCE_REASON =
  'Revisión tras aterrizaje de emergencia';

export type NewIncident = {
  orderId: string;
  droneId: string;
  hubId: string;
  kind: IncidentKind;
  leg: RouteLeg;
  protocol: ContingencyProtocol;
  position: LngLat;
  batteryPercent: number;
  /** El pedido, si el paquete va a bordo. `null`: el dron vuelve vacío. */
  packageOf: Order | null;
};

/** Lo que se publica de un incidente: sin el medicamento (RNF-05). */
export type IncidentJson = {
  id: string;
  orderId: string;
  droneId: string;
  hubId: string;
  kind: IncidentKind;
  severity: 'minor' | 'major';
  leg: RouteLeg;
  protocol: ContingencyProtocol;
  outcome: IncidentOutcome;
  latitude: number;
  longitude: number;
  batteryPercent: number;
  landingLatitude: number | null;
  landingLongitude: number | null;
  rescueDueAt: string | null;
  packageOnBoard: boolean;
  /** Choque grave o dron perdido con paquete a bordo. */
  packageLost: boolean;
  occurredAt: string;
  resolvedAt: string | null;
};

export function presentIncident(row: FlightIncident): IncidentJson {
  return {
    id: row.id,
    orderId: row.orderId,
    droneId: row.droneId,
    hubId: row.hubId,
    kind: row.kind,
    severity: row.severity,
    leg: row.leg,
    protocol: row.protocol,
    outcome: row.outcome,
    latitude: row.latitude,
    longitude: row.longitude,
    batteryPercent: row.batteryPercent,
    landingLatitude: row.landingLatitude,
    landingLongitude: row.landingLongitude,
    rescueDueAt: row.rescueDueAt ? row.rescueDueAt.toISOString() : null,
    packageOnBoard: row.packageQuantity != null,
    packageLost: row.packageQuantity != null && losesPackage(row.kind),
    occurredAt: new Date(row.occurredAt).toISOString(),
    resolvedAt: row.resolvedAt ? row.resolvedAt.toISOString() : null,
  };
}

function initialOutcome(protocol: ContingencyProtocol): IncidentOutcome {
  if (protocol === ContingencyProtocol.RETURN_TO_HUB) {
    return IncidentOutcome.RETURNING;
  }
  if (
    protocol === ContingencyProtocol.EMERGENCY_LANDING ||
    protocol === ContingencyProtocol.CRASH
  ) {
    return IncidentOutcome.LANDING;
  }
  if (protocol === ContingencyProtocol.LOST) {
    return IncidentOutcome.LOST;
  }
  return IncidentOutcome.CONTINUED;
}

/** RF-34: con choque grave o dron perdido, el paquete no se recupera. */
export function losesPackage(kind: IncidentKind): boolean {
  return (
    kind === IncidentKind.COLLISION_MAJOR || kind === IncidentKind.DRONE_LOST
  );
}

export const CRASH_REASON = 'Daño por choque grave';
export const LOST_REASON = 'Dron perdido en vuelo';

/**
 * RF-34 y CU-32: guarda cada incidente y lo cuenta, deja el paquete en
 * cuarentena y rescata al dron que aterrizó de emergencia. No decide el
 * protocolo (`contingency.rules.ts`) ni mueve el dron (`FlightClockService`).
 */
@Injectable()
export class FlightIncidentsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(FlightIncidentsService.name);
  private timer: NodeJS.Timeout | null = null;
  private sweeping = false;

  constructor(
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly notifications: NotificationsService,
  ) {}

  onModuleInit(): void {
    this.timer = simClock.every(RESCUE_SWEEP_MS, () => {
      void this.rescueDue();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async record(input: NewIncident): Promise<FlightIncident> {
    const repo = this.dataSource.getRepository(FlightIncident);
    const now = simClock.now();
    const outcome = initialOutcome(input.protocol);
    const order = input.packageOf;
    const saved = await repo.save(
      repo.create({
        orderId: input.orderId,
        droneId: input.droneId,
        hubId: input.hubId,
        kind: input.kind,
        severity: incidentSeverity(input.kind),
        leg: input.leg,
        protocol: input.protocol,
        outcome,
        latitude: input.position.latitude,
        longitude: input.position.longitude,
        batteryPercent: Math.round(input.batteryPercent * 10) / 10,
        landingLatitude: null,
        landingLongitude: null,
        rescueDueAt: null,
        packageMedication: order?.medicationName ?? null,
        packageSaleType: order?.saleType ?? null,
        packageQuantity: order?.quantity ?? null,
        packageLot: order?.dispatchedLot ?? null,
        packageLotExpiresOn: order?.dispatchedLotExpiresOn ?? null,
        resolvedAt:
          outcome === IncidentOutcome.CONTINUED ||
          outcome === IncidentOutcome.LOST
            ? now
            : null,
      }),
    );
    await this.announce(saved);
    return saved;
  }

  /** El aterrizaje de emergencia va hacia este punto. */
  async setLanding(id: string, landing: LngLat): Promise<void> {
    await this.dataSource.getRepository(FlightIncident).update(
      { id },
      {
        landingLatitude: landing.latitude,
        landingLongitude: landing.longitude,
      },
    );
  }

  /**
   * Tocó tierra fuera de base. El rescate sale de su central por tierra y
   * tarda según la distancia (`rescueDurationMs`).
   */
  async grounded(id: string, landing: LngLat): Promise<FlightIncident | null> {
    const repo = this.dataSource.getRepository(FlightIncident);
    const incident = await repo.findOne({ where: { id } });
    if (!incident) {
      return null;
    }
    const hub = await this.dataSource
      .getRepository(Hub)
      .findOne({ where: { id: incident.hubId } });
    const now = simClock.now();
    incident.outcome = IncidentOutcome.GROUNDED;
    incident.landingLatitude = landing.latitude;
    incident.landingLongitude = landing.longitude;
    incident.rescueDueAt = new Date(
      now.getTime() +
        (hub
          ? rescueDurationMs(
              { latitude: hub.latitude, longitude: hub.longitude },
              landing,
            )
          : 0),
    );
    const saved = await repo.save(incident);
    await this.announce(saved);
    return saved;
  }

  /**
   * Volvió a la central con el paquete: el paquete queda en cuarentena sin
   * pasar por la revisión del despachador (decisión del 2026-11-06).
   */
  async returnedHome(id: string): Promise<void> {
    const saved = await this.dataSource.transaction(async (manager) => {
      const incident = await manager.findOne(FlightIncident, {
        where: { id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident || incident.outcome !== IncidentOutcome.RETURNING) {
        return null;
      }
      await this.quarantine(manager, incident);
      incident.outcome = IncidentOutcome.RETURNED;
      incident.resolvedAt = simClock.now();
      return manager.save(incident);
    });
    if (saved) {
      await this.announce(saved);
    }
  }

  /** Los rescates que ya llegaron a su central. */
  async rescueDue(now = simClock.now()): Promise<number> {
    if (this.sweeping) {
      return 0;
    }
    this.sweeping = true;
    let rescued = 0;
    try {
      const due = await this.dataSource.getRepository(FlightIncident).find({
        where: {
          outcome: IncidentOutcome.GROUNDED,
          rescueDueAt: LessThanOrEqual(now),
        },
      });
      for (const incident of due) {
        try {
          if (await this.rescue(incident.id, now)) {
            rescued += 1;
          }
        } catch (error) {
          const message = error instanceof Error ? error.message : 'rescate';
          this.logger.error(
            `No se pudo cerrar el rescate de ${incident.droneId}: ${message}`,
          );
        }
      }
    } finally {
      this.sweeping = false;
    }
    return rescued;
  }

  /**
   * RF-34: el dron vuelve a su central y entra al taller, o queda fuera de
   * servicio si fue un choque grave. Su paquete queda en cuarentena, salvo
   * que se haya perdido. Si el pedido iba de regreso con ese paquete, llega
   * con él.
   */
  private async rescue(id: string, now: Date): Promise<boolean> {
    const result = await this.dataSource.transaction(async (manager) => {
      const incident = await manager.findOne(FlightIncident, {
        where: { id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident || incident.outcome !== IncidentOutcome.GROUNDED) {
        return null;
      }
      const wreck = losesPackage(incident.kind);
      const returned = await this.retire(manager, incident, now, {
        status: wreck ? DroneStatus.OUT_OF_SERVICE : DroneStatus.MAINTENANCE,
        reason: wreck ? CRASH_REASON : RESCUE_MAINTENANCE_REASON,
      });
      incident.outcome = IncidentOutcome.RESCUED;
      incident.resolvedAt = now;
      return { incident: await manager.save(incident), returned };
    });
    if (!result) {
      return false;
    }
    if (result.returned) {
      await this.notifications.statusChanged(
        result.incident.orderId,
        OrderStatus.RETURNED,
      );
    }
    await this.announce(result.incident);
    return true;
  }

  /**
   * RF-34: dron perdido. No hay rescate: queda fuera de servicio ya y el
   * paquete se da por perdido. Devuelve si el pedido volvía con él.
   */
  async lose(id: string): Promise<boolean> {
    const now = simClock.now();
    const returned = await this.dataSource.transaction(async (manager) => {
      const incident = await manager.findOne(FlightIncident, {
        where: { id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!incident) {
        return false;
      }
      return this.retire(manager, incident, now, {
        status: DroneStatus.OUT_OF_SERVICE,
        reason: LOST_REASON,
      });
    });
    if (returned) {
      const incident = await this.dataSource
        .getRepository(FlightIncident)
        .findOne({ where: { id } });
      if (incident) {
        await this.notifications.statusChanged(
          incident.orderId,
          OrderStatus.RETURNED,
        );
      }
    }
    return returned;
  }

  /** Saca al dron de la flota, cierra su misión y resuelve el paquete. */
  private async retire(
    manager: EntityManager,
    incident: FlightIncident,
    now: Date,
    to: {
      status: DroneStatus.MAINTENANCE | DroneStatus.OUT_OF_SERVICE;
      reason: string;
    },
  ): Promise<boolean> {
    const drone = await manager.findOne(Drone, {
      where: { id: incident.droneId },
      lock: { mode: 'pessimistic_write' },
    });
    if (
      drone &&
      (drone.status === DroneStatus.GROUNDED ||
        drone.status === DroneStatus.IN_MISSION)
    ) {
      drone.status = to.status;
      drone.maintenanceReason = to.reason;
      drone.maintenanceUntil = null;
      await manager.save(drone);
      await manager.save(
        manager.create(DroneMaintenance, {
          droneId: drone.id,
          kind:
            to.status === DroneStatus.OUT_OF_SERVICE
              ? DroneMaintenanceKind.OUT_OF_SERVICE
              : DroneMaintenanceKind.MAINTENANCE,
          reason: to.reason,
          estimatedEndDate: null,
          flightsAtStart: drone.flightsSinceMaintenance,
          openedByUserId: null,
          startedAt: now,
          closedAt: null,
          closedByUserId: null,
        }),
      );
    }
    await manager.update(
      Mission,
      {
        orderId: incident.orderId,
        droneId: incident.droneId,
        returnedAt: IsNull(),
      },
      { returnedAt: now },
    );
    const lost = losesPackage(incident.kind);
    if (!lost) {
      await this.quarantine(manager, incident);
    }
    const order = await manager.findOne(Order, {
      where: { id: incident.orderId },
      lock: { mode: 'pessimistic_write' },
    });
    // Volvía con el paquete (nadie lo retiró): el pedido se cierra aquí, sin
    // revisión del despachador.
    if (
      order?.status === OrderStatus.RETURNING &&
      order.droneId === incident.droneId
    ) {
      order.status = OrderStatus.RETURNED;
      order.returnCheckedAt = now;
      order.returnOutcome = lost
        ? ReturnOutcome.LOST
        : ReturnOutcome.QUARANTINED;
      await manager.save(order);
      return true;
    }
    return false;
  }

  private async quarantine(
    manager: EntityManager,
    incident: FlightIncident,
  ): Promise<void> {
    if (
      incident.packageQuantity == null ||
      !incident.packageMedication ||
      !incident.packageSaleType ||
      !incident.packageLot ||
      !incident.packageLotExpiresOn
    ) {
      return;
    }
    await manager.save(
      manager.create(QuarantineRecord, {
        orderId: incident.orderId,
        hubId: incident.hubId,
        medicationName: incident.packageMedication,
        saleType: incident.packageSaleType,
        lot: incident.packageLot,
        expirationDate: incident.packageLotExpiresOn,
        quantity: incident.packageQuantity,
        reason: QuarantineReason.INCIDENT,
      }),
    );
  }

  /** RF-39: los abiertos y los últimos resueltos, primero el más reciente. */
  async recent(limit = 50): Promise<IncidentJson[]> {
    const rows = await this.dataSource.getRepository(FlightIncident).find({
      order: { occurredAt: 'DESC' },
      take: limit,
    });
    return rows.map(presentIncident);
  }

  /**
   * Los que siguen abiertos en estas centrales, primero el más reciente:
   * el mapa del operador los pinta al abrirse y el socket los actualiza.
   */
  async openForHubs(hubIds: string[]): Promise<IncidentJson[]> {
    if (!hubIds.length) {
      return [];
    }
    const rows = await this.dataSource.getRepository(FlightIncident).find({
      where: { hubId: In(hubIds), resolvedAt: IsNull() },
      order: { occurredAt: 'DESC' },
    });
    return rows.map(presentIncident);
  }

  /** Aterrizajes de emergencia sin rescatar, por dron (alertas pendientes). */
  async openLandings(droneIds: string[]): Promise<Map<string, FlightIncident>> {
    const open = new Map<string, FlightIncident>();
    if (!droneIds.length) {
      return open;
    }
    const rows = await this.dataSource.getRepository(FlightIncident).find({
      where: {
        droneId: In(droneIds),
        outcome: In([IncidentOutcome.LANDING, IncidentOutcome.GROUNDED]),
      },
    });
    for (const row of rows) {
      open.set(row.droneId, row);
    }
    return open;
  }

  private async announce(incident: FlightIncident): Promise<void> {
    await this.notifications.incident(presentIncident(incident));
  }
}
