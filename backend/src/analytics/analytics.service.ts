import { Injectable } from '@nestjs/common';
import { And, DataSource, In, LessThan, MoreThanOrEqual } from 'typeorm';
import { HubStatus } from '../common/enums/hub-status.enum';
import { DeliveryCode } from '../delivery/delivery-code.entity';
import { DELIVERY_CODE_MAX_ATTEMPTS } from '../delivery/delivery.rules';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { QuarantineRecord } from '../inventory/quarantine-record.entity';
import { Order } from '../orders/order.entity';
import { addCalendarDays, todayInColombia } from '../orders/orders.rules';
import { Mission } from '../simulation/mission.entity';
import {
  EXPIRING_SOON_DAYS,
  FleetSnapshot,
  OrderFact,
  Period,
  PeriodFacts,
  breakdown,
  buildDemand,
  buildHubRanking,
  buildKpis,
  previousPeriod,
  resolvePeriod,
} from './analytics.rules';
import { AnalyticsQueryDto } from './dto/analytics-query.dto';

type RouteKm = { orderId: string; km: string | number };

/**
 * Carga los hechos del periodo y deja el cálculo a `analytics.rules`. Solo
 * lee: no expone nombres, documentos ni direcciones.
 */
@Injectable()
export class AnalyticsService {
  constructor(private readonly dataSource: DataSource) {}

  async kpis(query: AnalyticsQueryDto) {
    const period = resolvePeriod(query.from, query.to);
    const before = previousPeriod(period);
    const [current, previous, snapshot] = await Promise.all([
      this.facts(period, query.hubId),
      this.facts(before, query.hubId),
      this.snapshot(query.hubId),
    ]);
    return {
      period: publicPeriod(period),
      previousPeriod: publicPeriod(before),
      hubId: query.hubId ?? null,
      groups: buildKpis(current, previous, snapshot),
      ...breakdown(current.orders),
    };
  }

  async demand(query: AnalyticsQueryDto) {
    const period = resolvePeriod(query.from, query.to);
    const [current, hubNames] = await Promise.all([
      this.facts(period, query.hubId),
      this.hubNames(),
    ]);
    return {
      period: publicPeriod(period),
      hubId: query.hubId ?? null,
      ...buildDemand(current.orders, hubNames),
    };
  }

  async hubs(query: AnalyticsQueryDto) {
    const period = resolvePeriod(query.from, query.to);
    const [current, snapshot, hubNames] = await Promise.all([
      this.facts(period),
      this.snapshot(),
      this.hubNames(),
    ]);
    return {
      period: publicPeriod(period),
      hubs: buildHubRanking(current, snapshot, hubNames),
    };
  }

  /** Pedidos creados en el periodo; con `hubId`, los que despachó esa central. */
  private async facts(period: Period, hubId?: string): Promise<PeriodFacts> {
    const createdAt = And(MoreThanOrEqual(period.from), LessThan(period.to));
    const orders = await this.dataSource.getRepository(Order).find({
      where: hubId ? { createdAt, originHubId: hubId } : { createdAt },
    });
    const quarantine = await this.dataSource
      .getRepository(QuarantineRecord)
      .find({ where: hubId ? { createdAt, hubId } : { createdAt } });
    const quarantinedUnits = quarantine.reduce(
      (sum, record) => sum + record.quantity,
      0,
    );
    if (!orders.length) {
      return { period, orders: [], quarantinedUnits };
    }
    const ids = orders.map((order) => order.id);
    const [codes, missions, routes] = await Promise.all([
      this.dataSource
        .getRepository(DeliveryCode)
        .find({ where: { orderId: In(ids) } }),
      this.dataSource
        .getRepository(Mission)
        .find({ where: { orderId: In(ids) } }),
      this.dataSource.query<RouteKm[]>(
        `SELECT "orderId", SUM("distanceKm") AS km
         FROM mission_routes
         WHERE "orderId" = ANY($1::uuid[])
         GROUP BY "orderId"`,
        [ids],
      ),
    ]);
    const codeBy = new Map(codes.map((code) => [code.orderId, code]));
    const missionBy = new Map(
      missions.map((mission) => [mission.orderId, mission]),
    );
    const kmBy = new Map(routes.map((row) => [row.orderId, Number(row.km)]));
    return {
      period,
      quarantinedUnits,
      orders: orders.map((order) =>
        toFact(
          order,
          codeBy.get(order.id) ?? null,
          missionBy.get(order.id) ?? null,
          kmBy.get(order.id) ?? 0,
        ),
      ),
    };
  }

  /** Estado de hoy de la flota y del stock; no depende del periodo. */
  private async snapshot(hubId?: string): Promise<FleetSnapshot> {
    const today = todayInColombia();
    const [drones, hubs, expiring] = await Promise.all([
      this.dataSource
        .getRepository(Drone)
        .find({ where: hubId ? { hubId } : {} }),
      this.dataSource.getRepository(Hub).find({
        where: hubId
          ? { id: hubId, status: HubStatus.ACTIVE }
          : { status: HubStatus.ACTIVE },
      }),
      this.dataSource.query<Array<{ units: string | number }>>(
        `SELECT COALESCE(SUM(quantity), 0) AS units
         FROM inventory_items
         WHERE "expirationDate" >= $1 AND "expirationDate" <= $2
           AND ($3::uuid IS NULL OR "hubId" = $3)`,
        [today, addCalendarDays(today, EXPIRING_SOON_DAYS), hubId ?? null],
      ),
    ]);
    return {
      drones: drones.map((drone) => ({
        hubId: drone.hubId,
        status: drone.status,
      })),
      activeHubIds: hubs.map((hub) => hub.id),
      expiringUnits: Number(expiring[0]?.units ?? 0),
    };
  }

  private async hubNames(): Promise<Map<string, string>> {
    const hubs = await this.dataSource.getRepository(Hub).find();
    return new Map(hubs.map((hub) => [hub.id, hub.name]));
  }
}

function toFact(
  order: Order,
  code: DeliveryCode | null,
  mission: Mission | null,
  kmFlown: number,
): OrderFact {
  return {
    missionType: order.missionType,
    destinationKind: order.destinationKind,
    status: order.status,
    medicationName: order.medicationName,
    quantity: order.quantity,
    originHubId: order.originHubId,
    destinationHubId: order.destinationHubId,
    latitude: order.latitude,
    longitude: order.longitude,
    createdAt: order.createdAt,
    authorizedAt: order.authorizedAt,
    loadConfirmedAt: order.loadConfirmedAt,
    deliveredAt: code?.usedAt ?? null,
    flightStartedAt: mission?.startedAt ?? null,
    landedAt: mission?.landedAt ?? null,
    returnedAt: mission?.returnedAt ?? null,
    codeLocked: (code?.attempts ?? 0) >= DELIVERY_CODE_MAX_ATTEMPTS,
    coldChainAlert: order.coldChainAlertAt != null,
    batteryIncident: Boolean(mission?.batteryAlert || mission?.failureAlert),
    fallbackKind: order.fallbackKind,
    reassigned: order.reassignedFromHubId != null,
    kmFlown,
  };
}

function publicPeriod(period: Period) {
  return { from: period.fromDate, to: period.toDate };
}
