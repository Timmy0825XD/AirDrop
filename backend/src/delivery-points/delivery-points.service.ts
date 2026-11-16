import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, In, Repository } from 'typeorm';
import { DELIVERY_POINTS, NODES } from '../airspace/regional-network';
import { HubStatus } from '../common/enums/hub-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { rankHubsByDistance } from '../decision/fallback.rules';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { todayInColombia } from '../orders/orders.rules';
import { LngLat } from '../routing/routing.rules';
import { User } from '../users/user.entity';
import { DeliveryPoint } from './delivery-point.entity';
import {
  CoverageStatus,
  DELIVERY_POINT_NOT_FOUND,
  DELIVERY_POINT_UNAVAILABLE,
  coverageMessage,
  isAvailable,
  rankByDistance,
} from './delivery-points.rules';

/** Hasta tres centrales en la alternativa terrestre, como en RF-18. */
const GROUND_OPTIONS = 3;

/** RF-18: una central donde recoger por tierra. */
export type GroundOption = {
  hubId: string;
  name: string;
  address: string;
  contactPhone: string;
  contactEmail: string | null;
  distanceKm: number | null;
};

/**
 * RF-45: los puntos de entrega de la red. El escenario los crea al arrancar
 * y la semilla los vuelve a enlazar con su nodo; el administrador solo los
 * activa o los desactiva.
 */
@Injectable()
export class DeliveryPointsService implements OnModuleInit {
  constructor(
    @InjectRepository(DeliveryPoint)
    private readonly points: Repository<DeliveryPoint>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    @InjectRepository(InventoryItem)
    private readonly items: Repository<InventoryItem>,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.syncScenario(this.points.manager, false);
  }

  /**
   * Crea o corrige los puntos del escenario y los enlaza con su nodo por el
   * nombre. Con `reactivate` (semilla y reinicio, RF-40) todos quedan
   * activos; al arrancar se respeta lo que decidió el administrador.
   */
  async syncScenario(
    manager: EntityManager,
    reactivate: boolean,
  ): Promise<number> {
    const repo = manager.getRepository(DeliveryPoint);
    const nodeList = Object.values(NODES);
    const nodes = await manager
      .getRepository(Hub)
      .find({ where: { name: In(nodeList.map((node) => node.name)) } });
    for (const site of DELIVERY_POINTS) {
      const node = nodeList.find((entry) => entry.code === site.nodeCode);
      const hub = nodes.find((row) => row.name === node?.name) ?? null;
      const values = {
        code: site.code,
        name: site.name,
        municipality: site.municipality,
        latitude: site.latitude,
        longitude: site.longitude,
        elevationM: site.elevationM,
        hubId: hub?.id ?? null,
      };
      const existing = await repo.findOne({ where: { code: site.code } });
      if (existing) {
        await repo.save(
          repo.merge(
            existing,
            reactivate ? { ...values, active: true } : values,
          ),
        );
      } else {
        await repo.save(repo.create({ ...values, active: true }));
      }
    }
    return DELIVERY_POINTS.length;
  }

  /**
   * RU-02 y RF-45: los puntos, del más cercano al GPS al más lejano. Si el
   * solicitante está en la ciudad o no hay punto disponible, la respuesta
   * trae el motivo y la alternativa terrestre en vez del punto propuesto.
   */
  async coverage(
    user: User,
    query: { latitude?: number; longitude?: number; medicationName?: string },
  ) {
    const from =
      query.latitude != null && query.longitude != null
        ? { latitude: query.latitude, longitude: query.longitude }
        : null;
    const rows = await this.points.find({ order: { name: 'ASC' } });
    const status = await this.hubStatus(rows);
    const visible =
      user.role === UserRole.ADMIN
        ? rows
        : rows.filter((row) => isAvailable(row, status));
    const ranked = rankByDistance(visible, from).map((row) => ({
      ...this.present(row),
      available: isAvailable(row, status),
      distanceKm: row.distanceKm,
    }));
    const coverage = this.coverageStatus(ranked);
    const nearest =
      coverage === CoverageStatus.COVERED && from
        ? (ranked.find((row) => row.available) ?? null)
        : null;
    return {
      coverage,
      message: coverageMessage(coverage),
      nearestPointId: nearest?.id ?? null,
      points: ranked,
      alternatives:
        coverage !== CoverageStatus.COVERED && query.medicationName
          ? await this.groundAlternatives(query.medicationName, from)
          : [],
    };
  }

  /** RF-45: el administrador activa o desactiva un punto. */
  async setActive(id: string, active: boolean) {
    const point = await this.points.findOne({ where: { id } });
    if (!point) {
      throw new NotFoundException(DELIVERY_POINT_NOT_FOUND);
    }
    point.active = active;
    await this.points.save(point);
    return this.present(point);
  }

  /**
   * El punto al que va un pedido: debe existir, estar activo y tener su nodo
   * activo (RU-02).
   */
  async requireForOrder(id: string): Promise<DeliveryPoint> {
    const point = await this.points.findOne({ where: { id } });
    if (!point) {
      throw new NotFoundException(DELIVERY_POINT_NOT_FOUND);
    }
    const status = await this.hubStatus([point]);
    if (!isAvailable(point, status)) {
      throw new BadRequestException(DELIVERY_POINT_UNAVAILABLE);
    }
    return point;
  }

  /** RF-37: los destinos de los solicitantes simulados. */
  async available(): Promise<DeliveryPoint[]> {
    const rows = await this.points.find({ order: { name: 'ASC' } });
    const status = await this.hubStatus(rows);
    return rows.filter((row) => isAvailable(row, status));
  }

  present(point: DeliveryPoint) {
    return {
      id: point.id,
      code: point.code,
      name: point.name,
      municipality: point.municipality,
      latitude: point.latitude,
      longitude: point.longitude,
      elevationM: point.elevationM,
      hubId: point.hubId,
      active: point.active,
    };
  }

  private coverageStatus(
    ranked: Array<{ available: boolean }>,
  ): CoverageStatus {
    return ranked.some((row) => row.available)
      ? CoverageStatus.COVERED
      : CoverageStatus.NO_POINT;
  }

  private async hubStatus(
    points: DeliveryPoint[],
  ): Promise<Map<string, HubStatus>> {
    const ids = [
      ...new Set(
        points
          .map((point) => point.hubId)
          .filter((id): id is string => id != null),
      ),
    ];
    if (!ids.length) {
      return new Map();
    }
    const hubs = await this.hubs.find({ where: { id: In(ids) } });
    return new Map(hubs.map((hub) => [hub.id, hub.status]));
  }

  /**
   * RF-18: las centrales activas (nodo o ESE) que tienen el insumo vigente,
   * para recogerlo por tierra. Sin GPS, en orden alfabético.
   */
  private async groundAlternatives(
    medicationName: string,
    from: LngLat | null,
  ): Promise<GroundOption[]> {
    const rows = await this.items
      .createQueryBuilder('item')
      .innerJoin('item.hub', 'hub')
      .where('hub.status = :active', { active: HubStatus.ACTIVE })
      .andWhere('item.quantity > 0')
      .andWhere('item.expirationDate >= :today', { today: todayInColombia() })
      .andWhere('LOWER(item.name) = :name', {
        name: medicationName.trim().toLowerCase(),
      })
      .select('DISTINCT item."hubId"', 'hubId')
      .getRawMany<{ hubId: string }>();
    if (!rows.length) {
      return [];
    }
    const hubs = await this.hubs.find({
      where: { id: In(rows.map((row) => row.hubId)) },
      order: { name: 'ASC' },
    });
    const ranked = from
      ? rankHubsByDistance(hubs, from)
      : hubs.map((hub) => ({ hub, distanceKm: null }));
    return ranked.slice(0, GROUND_OPTIONS).map(({ hub, distanceKm }) => ({
      hubId: hub.id,
      name: hub.name,
      address: hub.address,
      contactPhone: hub.contactPhone,
      contactEmail: hub.contactEmail,
      distanceKm,
    }));
  }
}
