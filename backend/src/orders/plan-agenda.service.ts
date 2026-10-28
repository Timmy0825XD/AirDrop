import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { presentOrder } from './order.presenter';
import { DeliveryPlan } from './delivery-plan.entity';
import { Order } from './order.entity';
import { CatalogRow, InventoryOfferQuery } from './inventory-offer.query';
import {
  DEFAULT_CRUISE_KMH,
  SLOT_LOAD,
  buildAgenda,
  colombiaClock,
  departBefore,
  prescriptionStillValid,
} from './plan-dispatch.rules';
import { slotFor } from './plan-schedule.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { outboundDurationMs } from '../simulation/simulation.rules';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';

type PlanView = { id: string; originHubId: string | null };

/**
 * Agenda del día de una central (RU-30): franjas, confirmación, stock,
 * vigencia de la fórmula y la hora límite para despegar.
 */
@Injectable()
export class PlanAgendaService {
  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(DeliveryPlan)
    private readonly plans: Repository<DeliveryPlan>,
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    private readonly offers: InventoryOfferQuery,
    private readonly hubsService: HubsService,
    private readonly routes: RoutePlannerService,
  ) {}

  async list(user: User, date: string) {
    const hub = await this.requireDispatcherHub(user);
    const fleet = await this.fleetOf(hub.id);
    const stock = await this.stockByKey(hub.id);
    const pending = await this.orders.find({
      where: { missionType: MissionType.SCHEDULED, scheduledFor: date },
      order: { scheduledAt: 'ASC' },
    });
    const mine = pending.filter((order) =>
      this.isDirectedToHub(order, hub.id, stock),
    );
    const plans = await this.plansOf(mine);
    const polygons = await this.routes.loadPolygons(this.orders.manager);
    const orders = mine.map((order) => {
      const slot = this.slotOf(order);
      const availableQuantity = this.availableAt(order, stock);
      const plan = order.planId ? plans.get(order.planId) : undefined;
      return {
        ...presentOrder(order),
        time: colombiaClock(slot.scheduledAt),
        confirmed: order.confirmedAt != null,
        stockOk: availableQuantity >= order.quantity,
        prescriptionValid: prescriptionStillValid(
          order.saleType,
          plan?.prescriptionValidUntil ?? null,
          date,
        ),
        departBefore: this.departBy(hub, slot.windowEndsAt, order, polygons, fleet.kmh),
        availableQuantity,
      };
    });
    return { date, ...buildAgenda(fleet.drones, orders) };
  }

  /** Aviso, no bloqueo: en alguna franja hay más entregas que drones. */
  async withCapacity<T extends PlanView>(plan: T) {
    return { ...plan, busySlots: await this.busySlots(plan) };
  }

  private async busySlots(plan: PlanView) {
    if (!plan.originHubId) {
      return [];
    }
    const fleet = await this.fleetOf(plan.originHubId);
    const rows = await this.orders.find({
      where: { planId: plan.id, status: In(SLOT_LOAD) },
    });
    const seen = new Set<string>();
    const busy: Array<{
      date: string;
      time: string;
      deliveries: number;
      drones: number;
    }> = [];
    for (const row of rows) {
      if (!row.scheduledAt || !row.scheduledFor) {
        continue;
      }
      const time = colombiaClock(row.scheduledAt);
      const key = `${row.scheduledFor}|${time}`;
      if (seen.has(key)) {
        continue;
      }
      seen.add(key);
      const deliveries = await this.orders.count({
        where: {
          originHubId: plan.originHubId,
          scheduledAt: row.scheduledAt,
          status: In(SLOT_LOAD),
        },
      });
      if (deliveries > fleet.drones) {
        busy.push({
          date: row.scheduledFor,
          time,
          deliveries,
          drones: fleet.drones,
        });
      }
    }
    return busy;
  }

  private departBy(
    hub: Hub,
    closesAt: Date,
    order: Order,
    polygons: Awaited<ReturnType<RoutePlannerService['loadPolygons']>>,
    kmh: number,
  ): string | null {
    if (order.latitude == null || order.longitude == null) {
      return null;
    }
    const corridor = this.routes.plan(
      { latitude: hub.latitude, longitude: hub.longitude },
      { latitude: order.latitude, longitude: order.longitude },
      polygons,
    );
    if (!corridor) {
      return null;
    }
    return departBefore(
      closesAt,
      outboundDurationMs(corridor, { maxSpeedKmh: kmh, maxRangeKm: 110 }),
    ).toISOString();
  }

  private slotOf(order: Order) {
    if (order.scheduledAt && order.windowEndsAt) {
      return { scheduledAt: order.scheduledAt, windowEndsAt: order.windowEndsAt };
    }
    return slotFor(order.scheduledFor as string, null);
  }

  private async fleetOf(hubId: string) {
    const rows = await this.drones.find({
      where: {
        hubId,
        status: In([DroneStatus.AVAILABLE, DroneStatus.IN_MISSION]),
      },
      relations: { droneModel: true },
    });
    const kmh =
      rows
        .map((row) => row.droneModel?.maxSpeedKmh)
        .find((speed) => speed != null && speed > 0) ?? DEFAULT_CRUISE_KMH;
    return { drones: rows.length, kmh };
  }

  private async plansOf(orders: Order[]) {
    const ids = [
      ...new Set(orders.map((order) => order.planId).filter(Boolean)),
    ] as string[];
    if (!ids.length) {
      return new Map<string, DeliveryPlan>();
    }
    const rows = await this.plans.find({ where: { id: In(ids) } });
    return new Map(rows.map((plan) => [plan.id, plan]));
  }

  private async stockByKey(hubId: string) {
    const rows = await this.offers.stockForHub(hubId);
    return new Map(
      rows.map((row) => [`${row.name.trim().toLowerCase()}|${row.saleType}`, row]),
    );
  }

  private availableAt(order: Order, stock: Map<string, CatalogRow>) {
    return (
      stock.get(
        `${order.medicationName.trim().toLowerCase()}|${order.saleType}`,
      )?.availableQuantity ?? 0
    );
  }

  private isDirectedToHub(
    order: Order,
    hubId: string,
    stock: Map<string, CatalogRow>,
  ) {
    if (order.originHubId) {
      return order.originHubId === hubId;
    }
    return this.availableAt(order, stock) >= order.quantity;
  }

  private async requireDispatcherHub(user: User) {
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException(
        'Solo el despachador consulta la agenda de una central.',
      );
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new ForbiddenException(
        'Debes tener una central asignada para gestionar pedidos.',
      );
    }
    return this.hubsService.requireActive(hubIds[0]);
  }
}
