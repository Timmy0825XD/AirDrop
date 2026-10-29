import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import {
  DRONE_HOLDING_STATUSES,
  activeOrderByDrone,
} from '../fleet/fleet-flights.rules';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { QuarantineRecord } from '../inventory/quarantine-record.entity';
import { Order } from '../orders/order.entity';
import { RoutePlannerService } from '../routing/route-planner.service';
import { Mission } from '../simulation/mission.entity';
import { LiveFlight } from '../simulation/simulation.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import {
  RADAR_QUEUE_STATUSES,
  countFleet,
  presentRadarFlight,
} from './radar.rules';

type GeofenceRow = {
  id: string;
  name: string;
  reason: string;
  polygon: string;
};

/**
 * Panorama en vivo para el administrador (vista web). Solo lee: la flota la
 * gestiona `FleetService` y el vuelo lo mueve el reloj de simulación.
 */
@Injectable()
export class RadarService {
  constructor(
    @InjectRepository(Hub) private readonly hubs: Repository<Hub>,
    @InjectRepository(Drone) private readonly drones: Repository<Drone>,
    @InjectRepository(Order) private readonly orders: Repository<Order>,
    @InjectRepository(Mission) private readonly missions: Repository<Mission>,
    @InjectRepository(InventoryItem)
    private readonly items: Repository<InventoryItem>,
    @InjectRepository(QuarantineRecord)
    private readonly quarantine: Repository<QuarantineRecord>,
    private readonly dataSource: DataSource,
    private readonly telemetry: TelemetryPublisher,
    private readonly routes: RoutePlannerService,
  ) {}

  /** Todo lo que el mapa dibuja al abrir: centrales, vuelos y geovallas. */
  async snapshot() {
    const [hubs, drones, geofences] = await Promise.all([
      this.hubs.find({ order: { name: 'ASC' } }),
      this.drones.find({ relations: { droneModel: true } }),
      this.geofences(),
    ]);
    const flights = await this.flightsOf(drones);
    return {
      hubs: hubs.map((hub) => ({
        id: hub.id,
        name: hub.name,
        type: hub.type,
        status: hub.status,
        latitude: hub.latitude,
        longitude: hub.longitude,
        fleet: countFleet(drones.filter((drone) => drone.hubId === hub.id)),
      })),
      flights,
      geofences,
    };
  }

  /** El panel lateral de una central: flota, inventario y pedidos en marcha. */
  async hubDetail(hubId: string) {
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    const [drones, items, quarantined, queue] = await Promise.all([
      this.drones.find({
        where: { hubId },
        relations: { droneModel: true },
        order: { identifier: 'ASC' },
      }),
      this.items.find({
        where: { hubId },
        order: { name: 'ASC', expirationDate: 'ASC' },
      }),
      this.quarantine.find({ where: { hubId } }),
      this.queueOf(hubId),
    ]);
    const flights = await this.flightsOf(drones);
    const flightByDrone = new Map(flights.map((f) => [f.droneId, f]));
    return {
      id: hub.id,
      name: hub.name,
      type: hub.type,
      status: hub.status,
      address: hub.address,
      latitude: hub.latitude,
      longitude: hub.longitude,
      contactPhone: hub.contactPhone,
      contactEmail: hub.contactEmail,
      fleet: countFleet(drones),
      drones: drones.map((drone) => ({
        id: drone.id,
        identifier: drone.identifier,
        modelName: drone.droneModel?.name ?? null,
        status: drone.status,
        maintenanceReason: drone.maintenanceReason,
        flight: flightByDrone.get(drone.id) ?? null,
      })),
      inventory: {
        totalUnits: items.reduce((sum, item) => sum + item.quantity, 0),
        items: items.map((item) => ({
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          lot: item.lot,
          expirationDate: item.expirationDate,
          requiresColdChain: item.requiresColdChain,
          saleType: item.saleType,
        })),
        quarantinedUnits: quarantined.reduce(
          (sum, record) => sum + record.quantity,
          0,
        ),
      },
      queue,
    };
  }

  /** Un vuelo seleccionado: su ruta de ida y, si ya empezó, la de regreso. */
  async flightDetail(orderId: string) {
    const order = await this.orders.findOne({ where: { id: orderId } });
    if (!order?.droneId) {
      throw new NotFoundException('Ese vuelo no existe.');
    }
    const drone = await this.drones.findOne({ where: { id: order.droneId } });
    if (!drone) {
      throw new NotFoundException('Ese vuelo no existe.');
    }
    const [[flight], outbound, back, hubs] = await Promise.all([
      this.flightsOf([drone], [order]),
      this.routes.findOutboundMany([orderId]),
      this.routes.findReturnMany([orderId]),
      this.hubs.find({
        where: {
          id: In([order.originHubId, order.destinationHubId].filter(Boolean)),
        },
      }),
    ]);
    return {
      flight: flight ?? null,
      route: outbound.get(orderId) ?? null,
      returnRoute: back.get(orderId) ?? null,
      originHub: this.hubName(hubs, order.originHubId),
      destinationHub: this.hubName(hubs, order.destinationHubId),
    };
  }

  private hubName(hubs: Hub[], id: string | null) {
    const hub = hubs.find((row) => row.id === id);
    return hub ? { id: hub.id, name: hub.name } : null;
  }

  /**
   * Un vuelo por cada dron en misión. Sin Redis el vuelo sigue en la lista,
   * solo que sin posición, y el mapa no lo dibuja.
   */
  private async flightsOf(drones: Drone[], known: Order[] = []) {
    const busy = drones.filter(
      (drone) => drone.status === DroneStatus.IN_MISSION,
    );
    if (!busy.length) {
      return [];
    }
    const ids = busy.map((drone) => drone.id);
    const holding = known.length
      ? known
      : await this.orders.find({
          where: { droneId: In(ids), status: In(DRONE_HOLDING_STATUSES) },
        });
    const active = activeOrderByDrone(holding, ids);
    const orders = [...active.values()];
    const [lives, missions] = await Promise.all([
      Promise.all(orders.map((order) => this.liveOf(order.id))),
      orders.length
        ? this.missions.find({
            where: { orderId: In(orders.map((order) => order.id)) },
          })
        : Promise.resolve([] as Mission[]),
    ]);
    const liveBy = new Map(orders.map((order, i) => [order.id, lives[i]]));
    const missionBy = new Map(missions.map((m) => [m.orderId, m]));
    return busy.flatMap((drone) => {
      const order = active.get(drone.id);
      if (!order) {
        return [];
      }
      const mission = missionBy.get(order.id);
      return [
        presentRadarFlight(drone, order, liveBy.get(order.id) ?? null, {
          battery: mission?.batteryAlert ?? false,
          failure: mission?.failureAlert ?? false,
        }),
      ];
    });
  }

  private async liveOf(orderId: string): Promise<LiveFlight | null> {
    try {
      return await this.telemetry.readFlight(orderId);
    } catch {
      return null;
    }
  }

  private async queueOf(hubId: string) {
    const rows: Array<{ status: string; count: number }> = await this.orders
      .createQueryBuilder('o')
      .select('o.status', 'status')
      .addSelect('COUNT(*)::int', 'count')
      .where('o."originHubId" = :hubId', { hubId })
      .andWhere('o.status IN (:...statuses)', {
        statuses: RADAR_QUEUE_STATUSES,
      })
      .groupBy('o.status')
      .getRawMany();
    return Object.fromEntries(rows.map((row) => [row.status, row.count]));
  }

  private async geofences() {
    const rows: GeofenceRow[] = await this.dataSource.query(
      `SELECT id, name, reason, ST_AsGeoJSON(polygon) AS polygon
       FROM geofences
       ORDER BY name ASC`,
    );
    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      reason: row.reason,
      polygon: JSON.parse(row.polygon) as unknown,
    }));
  }
}
