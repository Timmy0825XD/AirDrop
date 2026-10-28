import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { LiveFlight } from '../simulation/simulation.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { Drone } from './drone.entity';
import {
  DRONE_HOLDING_STATUSES,
  activeOrderByDrone,
} from './fleet-flights.rules';

/**
 * RU-18 y CU-19: qué pedido lleva cada dron del operador y cómo va. Solo
 * lee; la flota la gestiona `FleetService` y el vuelo lo mueve el reloj.
 */
@Injectable()
export class FleetFlightsService {
  constructor(
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Mission)
    private readonly missions: Repository<Mission>,
    private readonly telemetry: TelemetryPublisher,
  ) {}

  /** `GET /fleet/drones`: cada dron en misión trae su pedido y su fase. */
  async withActiveOrders<T extends { id: string; status: DroneStatus }>(
    drones: T[],
  ) {
    const busy = drones.filter(
      (drone) => drone.status === DroneStatus.IN_MISSION,
    );
    const active = await this.activeOrders(busy.map((drone) => drone.id));
    const flights = await this.readFlights([...active.values()]);
    return drones.map((drone) => {
      const order = active.get(drone.id) ?? null;
      return {
        ...drone,
        activeOrderId: order?.id ?? null,
        phase: order ? (flights.get(order.id)?.phase ?? null) : null,
      };
    });
  }

  /** `GET /fleet/flights`: los vuelos en curso de las centrales del operador. */
  async listFlights(user: User, hubId?: string) {
    const hubIds = assignedHubIds(user);
    if (hubId && !hubIds.includes(hubId)) {
      throw new ForbiddenException('Esa central no está asignada a tu cuenta.');
    }
    const drones = await this.drones.find({
      where: {
        hubId: In(hubId ? [hubId] : hubIds),
        status: DroneStatus.IN_MISSION,
      },
      order: { identifier: 'ASC' },
    });
    const active = await this.activeOrders(drones.map((drone) => drone.id));
    const orders = [...active.values()];
    const [flights, missions] = await Promise.all([
      this.readFlights(orders),
      orders.length
        ? this.missions.find({
            where: { orderId: In(orders.map((order) => order.id)) },
          })
        : Promise.resolve([]),
    ]);
    const missionBy = new Map(
      missions.map((mission) => [mission.orderId, mission]),
    );
    return drones.flatMap((drone) => {
      const order = active.get(drone.id);
      if (!order) {
        return [];
      }
      const flight = flights.get(order.id) ?? null;
      const mission = missionBy.get(order.id);
      return [
        {
          droneId: drone.id,
          identifier: drone.identifier,
          hubId: drone.hubId,
          orderId: order.id,
          orderStatus: order.status,
          missionType: order.missionType,
          requiresColdChain: order.requiresColdChain,
          phase: flight?.phase ?? null,
          leg: flight?.leg ?? null,
          latitude: flight?.latitude ?? null,
          longitude: flight?.longitude ?? null,
          batteryPercent: flight?.batteryPercent ?? null,
          temperatureC: flight?.temperatureC ?? null,
          etaSeconds: flight?.etaSeconds ?? null,
          alerts: {
            battery: mission?.batteryAlert ?? false,
            failure: mission?.failureAlert ?? false,
            coldChain: order.coldChainAlertAt != null,
          },
        },
      ];
    });
  }

  private async activeOrders(droneIds: string[]) {
    if (!droneIds.length) {
      return new Map<string, Order>();
    }
    const orders = await this.orders.find({
      where: {
        droneId: In(droneIds),
        status: In(DRONE_HOLDING_STATUSES),
      },
    });
    return activeOrderByDrone(orders, droneIds);
  }

  /** Sin Redis, el pedido sigue apareciendo, solo sin la fase ni la posición. */
  private async readFlights(orders: Order[]) {
    const flights = new Map<string, LiveFlight>();
    for (const order of orders) {
      try {
        const flight = await this.telemetry.readFlight(order.id);
        if (flight) {
          flights.set(order.id, flight);
        }
      } catch {
        // La lista de la flota no depende de la telemetría en vivo.
      }
    }
    return flights;
  }
}
