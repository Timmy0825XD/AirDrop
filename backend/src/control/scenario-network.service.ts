import { Injectable, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, EntityManager, In, Not } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubNetworkRole } from '../common/enums/hub-network-role.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { Hub } from '../hubs/hub.entity';
import { User } from '../users/user.entity';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { UsersService } from '../users/users.service';
import { DemoHubPlan, hubPlans, operator } from './demo-scenario';

/** La contraseña de las cuentas de la demostración (la de `pnpm seed:demo`). */
export const DEMO_PASSWORD = 'Password123';

/** Las tablas que cuelgan de un pedido, en el orden en que se borran. */
const ORDER_TABLES = [
  'delivery_codes',
  'prescription_images',
  'prescription_access_logs',
  'mission_routes',
  'missions',
  'flight_incidents',
  'notifications',
  'cargo_manifests',
];

/**
 * RF-40: antes de reiniciar, la red de la base queda igual a la del plan
 * (`demo-scenario.ts`): se borran las centrales que el plan ya no tiene (con
 * sus pedidos, drones, inventario y despachadores) y se crean las que faltan
 * (con sus despachadores, sus drones y el operador asignado). Así una base
 * vieja no muestra centrales de otra versión ni le faltan las nuevas.
 */
@Injectable()
export class ScenarioNetworkService {
  private readonly logger = new Logger(ScenarioNetworkService.name);

  constructor(
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly users: UsersService,
  ) {}

  async sync(admin: User): Promise<{ removed: number; created: number }> {
    const removed = await this.removeStaleHubs();
    const created = await this.createMissing(admin);
    if (removed || created) {
      this.logger.log(
        `Red del escenario: ${removed} centrales borradas y ${created} creadas.`,
      );
    }
    return { removed, created };
  }

  /** Las centrales que no están en el plan, con todo lo que cuelga de ellas. */
  removeStaleHubs(): Promise<number> {
    return this.dataSource.transaction((manager) => this.removeStale(manager));
  }

  private async removeStale(manager: EntityManager): Promise<number> {
    const stale = await manager.find(Hub, {
      where: { name: Not(In(hubPlans.map((plan) => plan.name))) },
    });
    if (!stale.length) {
      return 0;
    }
    const hubIds = stale.map((hub) => hub.id);
    // Sus despachadores: los que solo trabajan en centrales que se van.
    const dispatchers: Array<{ id: string }> = await manager.query(
      `SELECT u.id FROM users u
       WHERE u.role = $2
         AND EXISTS (SELECT 1 FROM user_hubs a WHERE a."userId" = u.id AND a."hubId" = ANY($1::uuid[]))
         AND NOT EXISTS (SELECT 1 FROM user_hubs a WHERE a."userId" = u.id AND NOT a."hubId" = ANY($1::uuid[]))`,
      [hubIds, UserRole.DISPATCHER],
    );
    const userIds = dispatchers.map((row) => row.id);
    const droneIds = (
      await manager.find(Drone, { where: { hubId: In(hubIds) } })
    ).map((drone) => drone.id);
    const orders: Array<{ id: string }> = await manager.query(
      `SELECT id FROM orders
       WHERE "originHubId" = ANY($1::uuid[])
          OR "destinationHubId" = ANY($1::uuid[])
          OR "droneId" = ANY($2::uuid[])
          OR "createdByUserId" = ANY($3::uuid[])`,
      [hubIds, droneIds, userIds],
    );
    const orderIds = orders.map((row) => row.id);
    for (const table of ORDER_TABLES) {
      await manager.query(
        `DELETE FROM ${table} WHERE "orderId" = ANY($1::uuid[])`,
        [orderIds],
      );
    }
    await manager.query(
      `DELETE FROM flight_incidents WHERE "droneId" = ANY($1::uuid[]) OR "hubId" = ANY($2::uuid[])`,
      [droneIds, hubIds],
    );
    for (const table of ['missions', 'cargo_manifests']) {
      await manager.query(
        `DELETE FROM ${table} WHERE "droneId" = ANY($1::uuid[])`,
        [droneIds],
      );
    }
    await manager.query(
      `DELETE FROM quarantine_records WHERE "orderId" = ANY($1::uuid[]) OR "hubId" = ANY($2::uuid[])`,
      [orderIds, hubIds],
    );
    await manager.query(`DELETE FROM orders WHERE id = ANY($1::uuid[])`, [
      orderIds,
    ]);
    await manager.query(
      `DELETE FROM delivery_plans
       WHERE "originHubId" = ANY($1::uuid[]) OR "destinationHubId" = ANY($1::uuid[])
          OR "createdByUserId" = ANY($2::uuid[])`,
      [hubIds, userIds],
    );
    await manager.query(
      `DELETE FROM drone_maintenances WHERE "droneId" = ANY($1::uuid[])`,
      [droneIds],
    );
    await manager.query(`DELETE FROM drones WHERE id = ANY($1::uuid[])`, [
      droneIds,
    ]);
    await manager.query(
      `DELETE FROM inventory_items WHERE "hubId" = ANY($1::uuid[])`,
      [hubIds],
    );
    await manager.query(
      `DELETE FROM user_hubs WHERE "hubId" = ANY($1::uuid[]) OR "userId" = ANY($2::uuid[])`,
      [hubIds, userIds],
    );
    for (const table of [
      'notifications',
      'one_time_codes',
      'prescription_access_logs',
    ]) {
      await manager.query(
        `DELETE FROM ${table} WHERE "userId" = ANY($1::uuid[])`,
        [userIds],
      );
    }
    await manager.query(`DELETE FROM users WHERE id = ANY($1::uuid[])`, [
      userIds,
    ]);
    await manager.query(`DELETE FROM hubs WHERE id = ANY($1::uuid[])`, [
      hubIds,
    ]);
    return stale.length;
  }

  /** Las centrales del plan que la base no tiene, con su gente y sus drones. */
  private async createMissing(admin: User): Promise<number> {
    const hubs = this.dataSource.getRepository(Hub);
    const existing = await hubs.find({
      where: { name: In(hubPlans.map((plan) => plan.name)) },
    });
    const missing = hubPlans.filter(
      (plan) => !existing.some((hub) => hub.name === plan.name),
    );
    for (const plan of missing) {
      const hub = await hubs.save(
        hubs.create({
          name: plan.name,
          type: plan.type,
          networkRole: plan.networkRole,
          address: plan.address,
          latitude: plan.latitude,
          longitude: plan.longitude,
          contactPhone: plan.contactPhone,
          contactEmail: plan.contactEmail,
          status: HubStatus.ACTIVE,
          createdByUserId: admin.id,
        }),
      );
      await this.createDispatchers(plan, hub);
      if (plan.networkRole === HubNetworkRole.NODE) {
        await this.createDrones(plan, hub);
        await this.assignOperator(hub);
      }
    }
    return missing.length;
  }

  private async createDispatchers(plan: DemoHubPlan, hub: Hub): Promise<void> {
    const repo = this.dataSource.getRepository(User);
    for (const person of plan.dispatchers) {
      if (await repo.findOne({ where: { email: person.email } })) {
        continue;
      }
      await this.users.createInstitutional({
        fullName: person.fullName,
        email: person.email,
        phone: person.phone,
        password: DEMO_PASSWORD,
        role: UserRole.DISPATCHER,
        hubIds: [hub.id],
      });
    }
  }

  /** La flota del plan; sus estados (taller) los pone el reinicio. */
  private async createDrones(plan: DemoHubPlan, hub: Hub): Promise<void> {
    const models = await this.dataSource.getRepository(DroneModel).find();
    const drones = this.dataSource.getRepository(Drone);
    for (const [index, spec] of plan.fleet.entries()) {
      const identifier = `${plan.dronePrefix}-0${index + 1}`;
      const model = models.find((row) => row.kind === spec.kind);
      if (!model || (await drones.findOne({ where: { identifier } }))) {
        continue;
      }
      await drones.save(
        drones.create({
          identifier,
          droneModelId: model.id,
          hubId: hub.id,
          status: DroneStatus.AVAILABLE,
          coldCompartment: spec.cold,
          maintenanceReason: null,
          maintenanceUntil: null,
        }),
      );
    }
  }

  /** El operador de la demo cuida también el nodo nuevo. */
  private async assignOperator(hub: Hub): Promise<void> {
    const person = await this.dataSource
      .getRepository(User)
      .findOne({ where: { email: operator.email } });
    if (!person) {
      return;
    }
    const assignments = this.dataSource.getRepository(UserHubAssignment);
    await assignments.save(
      assignments.create({ userId: person.id, hubId: hub.id }),
    );
  }
}
