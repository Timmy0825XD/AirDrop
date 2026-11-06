import { ForbiddenException, Injectable } from '@nestjs/common';
import {
  And,
  DataSource,
  In,
  IsNull,
  LessThan,
  MoreThanOrEqual,
  Not,
} from 'typeorm';
import { resolvePeriod } from '../analytics/analytics.rules';
import { AnalyticsQueryDto } from '../analytics/dto/analytics-query.dto';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { batteryNow } from '../simulation/flight-energy.rules';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { Drone } from './drone.entity';
import { DroneMaintenance } from './drone-maintenance.entity';
import {
  DashboardFlight,
  blockedByGeofence,
  buildFleetDashboard,
} from './fleet-dashboard.rules';
import { simClock } from '../common/clock/sim-clock';

type RouteFact = {
  orderId: string;
  km: number | string | null;
  latitude: number | string | null;
  longitude: number | string | null;
};

/**
 * CU-20 del operador: carga los vuelos, el taller y las trazas de sus
 * centrales en el periodo. Los números los calcula `fleet-dashboard.rules`.
 */
@Injectable()
export class FleetDashboardService {
  constructor(private readonly dataSource: DataSource) {}

  async dashboard(user: User, query: AnalyticsQueryDto, now = simClock.now()) {
    const assigned = assignedHubIds(user);
    if (query.hubId && !assigned.includes(query.hubId)) {
      throw new ForbiddenException('Esa central no está asignada a tu cuenta.');
    }
    const hubIds = query.hubId ? [query.hubId] : assigned;
    const period = resolvePeriod(query.from, query.to);
    const drones = await this.dataSource
      .getRepository(Drone)
      .find({ where: { hubId: In(hubIds) }, order: { identifier: 'ASC' } });
    const droneIds = drones.map((drone) => drone.id);
    const [flights, maintenance, geofenceBlocks] = await Promise.all([
      this.flights(droneIds, period.from, period.to),
      droneIds.length
        ? this.dataSource.getRepository(DroneMaintenance).find({
            where: [
              {
                droneId: In(droneIds),
                startedAt: LessThan(period.to),
                closedAt: IsNull(),
              },
              {
                droneId: In(droneIds),
                startedAt: LessThan(period.to),
                closedAt: MoreThanOrEqual(period.from),
              },
            ],
          })
        : Promise.resolve([]),
      this.geofenceBlocks(hubIds, period.from, period.to),
    ]);
    return buildFleetDashboard({
      period,
      now,
      drones: drones.map((drone) => ({
        id: drone.id,
        identifier: drone.identifier,
        hubId: drone.hubId,
        status: drone.status,
        batteryPercent: batteryNow(
          drone.batteryPercent ?? 100,
          drone.batteryUpdatedAt ?? null,
          now,
        ),
        flightsSinceMaintenance: drone.flightsSinceMaintenance ?? 0,
        maintenanceUntil: drone.maintenanceUntil,
        createdAt: drone.createdAt,
      })),
      flights,
      maintenance,
      geofenceBlocks,
    });
  }

  /** Los vuelos que despegaron en el periodo, con su corredor y sus alertas. */
  private async flights(
    droneIds: string[],
    from: Date,
    to: Date,
  ): Promise<DashboardFlight[]> {
    if (!droneIds.length) {
      return [];
    }
    const missions = await this.dataSource.getRepository(Mission).find({
      where: {
        droneId: In(droneIds),
        startedAt: And(MoreThanOrEqual(from), LessThan(to)),
      },
    });
    if (!missions.length) {
      return [];
    }
    const orderIds = missions.map((mission) => mission.orderId);
    const [orders, routes] = await Promise.all([
      this.dataSource.getRepository(Order).find({
        where: { id: In(orderIds) },
        select: { id: true, status: true, coldChainAlertAt: true },
      }),
      // Km de ida y regreso, y el punto donde termina la ida (el destino).
      this.dataSource.query<RouteFact[]>(
        `SELECT "orderId",
                SUM("distanceKm")::float8 AS km,
                MAX(CASE WHEN leg = 'outbound' THEN ST_Y(ST_EndPoint(path)) END) AS latitude,
                MAX(CASE WHEN leg = 'outbound' THEN ST_X(ST_EndPoint(path)) END) AS longitude
         FROM mission_routes
         WHERE "orderId" = ANY($1::uuid[])
         GROUP BY "orderId"`,
        [orderIds],
      ),
    ]);
    const orderBy = new Map(orders.map((order) => [order.id, order]));
    const routeBy = new Map(routes.map((route) => [route.orderId, route]));
    return missions.map((mission) => {
      const order = orderBy.get(mission.orderId);
      const route = routeBy.get(mission.orderId);
      return {
        droneId: mission.droneId,
        startedAt: mission.startedAt,
        returnedAt: mission.returnedAt,
        km: Number(route?.km ?? 0),
        landingBatteryPercent: mission.landingBatteryPercent ?? null,
        batteryAlert: mission.batteryAlert,
        failureAlert: mission.failureAlert,
        coldChainAlert: order?.coldChainAlertAt != null,
        returnedWithPackage: order?.status === OrderStatus.RETURNED,
        latitude: numberOrNull(route?.latitude),
        longitude: numberOrNull(route?.longitude),
      };
    });
  }

  /** Pedidos del periodo que una geovalla dejó sin corredor en estas centrales. */
  private async geofenceBlocks(hubIds: string[], from: Date, to: Date) {
    const orders = await this.dataSource.getRepository(Order).find({
      where: {
        createdAt: And(MoreThanOrEqual(from), LessThan(to)),
        decisionTrace: Not(IsNull()),
      },
      select: {
        id: true,
        status: true,
        statusReason: true,
        originHubId: true,
        decisionTrace: true,
        latitude: true,
        longitude: true,
      },
    });
    return orders
      .filter((order) => blockedByGeofence(order, hubIds))
      .map((order) => ({
        latitude: order.latitude,
        longitude: order.longitude,
      }));
  }
}

function numberOrNull(value: number | string | null | undefined) {
  if (value == null) {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}
