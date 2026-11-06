import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, EntityManager, In, IsNull } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneMaintenance } from '../fleet/drone-maintenance.entity';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { todayInColombia } from '../orders/orders.rules';
import { FlightClockService } from '../simulation/flight-clock.service';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { TelemetryRedis, telemetryKey } from '../telemetry/telemetry.redis';
import { User } from '../users/user.entity';
import { ClockControlService } from './clock-control.service';
import { geofences, hubPlans, operator } from './demo-scenario';
import {
  NO_DEMO_SCENARIO,
  ResetSummary,
  droneResetState,
  resetDetail,
  stockRows,
} from './scenario-reset.rules';
import { TimelineService } from './timeline.service';

/**
 * RF-40, CU-41: devuelve el escenario de `pnpm seed:demo` a su estado
 * inicial, sin crear ni borrar centrales ni cuentas (las sesiones abiertas
 * siguen sirviendo). Borra todo pedido de las centrales de la demo, también
 * los de personas reales: si quedaran vivos, tendrían un dron y un stock que
 * el reinicio acaba de devolver.
 */
@Injectable()
export class ScenarioResetService {
  private readonly logger = new Logger(ScenarioResetService.name);

  constructor(
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly flights: FlightClockService,
    private readonly clock: ClockControlService,
    private readonly timeline: TimelineService,
    private readonly redis: TelemetryRedis,
    private readonly publisher: TelemetryPublisher,
  ) {}

  async reset(admin: User): Promise<ResetSummary> {
    const hubs = await this.dataSource.getRepository(Hub).find({
      where: { name: In(hubPlans.map((plan) => plan.name)) },
    });
    if (!hubs.length) {
      throw new ConflictException(NO_DEMO_SCENARIO);
    }
    // Primero el reloj: los vencimientos y el mantenimiento cuentan desde hoy.
    await this.clock.resetToRealTime();
    const hubIds = hubs.map((hub) => hub.id);
    const orders = await this.scopedOrders(hubIds);
    const orderIds = orders.map((order) => order.id);
    await this.flights.forget(orderIds);

    const summary = await this.dataSource.transaction(async (manager) => {
      await this.deleteOrders(manager, orderIds, orders, hubIds);
      const inventoryItems = await this.resetStock(manager, hubs);
      const drones = await this.resetFleet(manager, hubs, admin);
      await manager.update(
        Hub,
        { id: In(hubIds) },
        { status: HubStatus.ACTIVE },
      );
      const fences = await this.resetGeofences(manager, admin);
      return {
        orders: orderIds.length,
        drones,
        inventoryItems,
        geofences: fences,
      };
    });

    await this.redis.remove(orderIds.map((id) => telemetryKey(id)));
    await this.timeline.clear();
    await this.publisher.publish({ type: 'scenario-reset' });
    await this.timeline.recordConsole(
      'Escenario reiniciado',
      resetDetail(summary),
    );
    this.logger.log(`Escenario reiniciado: ${resetDetail(summary)}`);
    return summary;
  }

  /**
   * Pedidos que salen, llegan o están ofrecidos (RU-10) a una central de la
   * demo. Una urgencia en cola todavía no tiene central de origen: su
   * central está en `dispatchOffers`.
   */
  private scopedOrders(
    hubIds: string[],
  ): Promise<Array<{ id: string; planId: string | null }>> {
    return this.dataSource.query(
      `SELECT id, "planId" FROM orders
       WHERE "originHubId" = ANY($1::uuid[])
          OR "destinationHubId" = ANY($1::uuid[])
          OR EXISTS (
            SELECT 1
            FROM jsonb_array_elements(COALESCE("dispatchOffers", '[]'::jsonb)) AS offer
            WHERE offer->>'hubId' = ANY($2::text[])
          )`,
      [hubIds, hubIds],
    );
  }

  private async deleteOrders(
    manager: EntityManager,
    orderIds: string[],
    orders: Array<{ planId: string | null }>,
    hubIds: string[],
  ): Promise<void> {
    const planIds = [...new Set(orders.flatMap((order) => order.planId ?? []))];
    if (orderIds.length) {
      for (const table of [
        'delivery_codes',
        'prescription_images',
        'mission_routes',
        'missions',
        'notifications',
      ]) {
        await manager.query(
          `DELETE FROM ${table} WHERE "orderId" = ANY($1::uuid[])`,
          [orderIds],
        );
      }
    }
    await manager.query(
      `DELETE FROM quarantine_records
       WHERE "orderId" = ANY($1::uuid[]) OR "hubId" = ANY($2::uuid[])`,
      [orderIds, hubIds],
    );
    if (orderIds.length) {
      await manager.query(`DELETE FROM orders WHERE id = ANY($1::uuid[])`, [
        orderIds,
      ]);
    }
    await manager.query(
      `DELETE FROM delivery_plans
       WHERE id = ANY($1::uuid[])
          OR "originHubId" = ANY($2::uuid[])
          OR "destinationHubId" = ANY($2::uuid[])`,
      [planIds, hubIds],
    );
  }

  /** Lotes de la semilla: los que entraron por traslados también se van. */
  private async resetStock(manager: EntityManager, hubs: Hub[]) {
    const today = todayInColombia(simClock.now());
    await manager.delete(InventoryItem, { hubId: In(hubs.map((h) => h.id)) });
    let count = 0;
    for (const hub of hubs) {
      const plan = hubPlans.find((entry) => entry.name === hub.name);
      if (!plan) {
        continue;
      }
      const rows = stockRows(plan, hub.id, today);
      await manager.save(
        InventoryItem,
        rows.map((row) => manager.create(InventoryItem, row)),
      );
      count += rows.length;
    }
    return count;
  }

  /** Cada dron en su central, con la batería llena y el estado de la semilla. */
  private async resetFleet(manager: EntityManager, hubs: Hub[], admin: User) {
    const today = todayInColombia(simClock.now());
    const now = simClock.now();
    const drones = await manager.find(Drone, {
      where: { hubId: In(hubs.map((hub) => hub.id)) },
    });
    for (const drone of drones) {
      const plan = hubPlans.find(
        (entry) => entry.name === hubs.find((h) => h.id === drone.hubId)?.name,
      );
      if (!plan) {
        continue;
      }
      const state = droneResetState(drone.identifier, plan, today);
      await manager.update(
        Drone,
        { id: drone.id },
        {
          ...state,
          batteryPercent: 100,
          batteryUpdatedAt: now,
          lastFlightEndedAt: null,
          flightsSinceMaintenance: 0,
          maintenanceDueNotifiedAt: null,
          maintenanceOverdueNotifiedAt: null,
        },
      );
      await this.syncMaintenancePeriod(manager, drone, state, admin, now);
    }
    return drones.length;
  }

  /** El historial de taller sigue al estado: disponible cierra, mantenimiento abre. */
  private async syncMaintenancePeriod(
    manager: EntityManager,
    drone: Drone,
    state: ReturnType<typeof droneResetState>,
    admin: User,
    now: Date,
  ): Promise<void> {
    const open = await manager.findOne(DroneMaintenance, {
      where: { droneId: drone.id, closedAt: IsNull() },
    });
    if (state.status === DroneStatus.AVAILABLE) {
      if (open) {
        await manager.update(
          DroneMaintenance,
          { id: open.id },
          { closedAt: now, closedByUserId: admin.id },
        );
      }
      return;
    }
    if (open?.kind === DroneMaintenanceKind.MAINTENANCE) {
      await manager.update(
        DroneMaintenance,
        { id: open.id },
        {
          reason: state.maintenanceReason,
          estimatedEndDate: state.maintenanceUntil,
        },
      );
      return;
    }
    if (open) {
      await manager.update(
        DroneMaintenance,
        { id: open.id },
        { closedAt: now, closedByUserId: admin.id },
      );
    }
    await manager.save(
      DroneMaintenance,
      manager.create(DroneMaintenance, {
        droneId: drone.id,
        kind: DroneMaintenanceKind.MAINTENANCE,
        reason: state.maintenanceReason,
        estimatedEndDate: state.maintenanceUntil,
        flightsAtStart: 0,
        openedByUserId: admin.id,
        startedAt: now,
        closedAt: null,
        closedByUserId: null,
      }),
    );
  }

  /** Las geovallas de la semilla vuelven a su forma; las demás no se tocan. */
  private async resetGeofences(manager: EntityManager, admin: User) {
    const owner = await manager.findOne(User, {
      where: { email: operator.email },
    });
    for (const fence of geofences) {
      await manager.query(`DELETE FROM geofences WHERE name = $1`, [
        fence.name,
      ]);
      await manager.query(
        `INSERT INTO geofences (id, name, reason, polygon, "createdByUserId")
         VALUES (gen_random_uuid(), $1, $2, ST_SetSRID(ST_GeomFromGeoJSON($3), 4326), $4)`,
        [
          fence.name,
          fence.reason,
          JSON.stringify(fence.polygon),
          owner?.id ?? admin.id,
        ],
      );
    }
    return geofences.length;
  }
}
