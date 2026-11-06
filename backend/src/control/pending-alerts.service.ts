import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { Drone } from '../fleet/drone.entity';
import { Order } from '../orders/order.entity';
import { FlightIncidentsService } from '../simulation/flight-incidents.service';
import { Mission } from '../simulation/mission.entity';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { PendingAlert, pendingAlertKinds } from './pending-alerts.rules';

/**
 * RF-39: alertas abiertas y dónde está cada dron. Se calculan de la base y de
 * la telemetría en vivo, así que un reinicio no las pierde.
 */
@Injectable()
export class PendingAlertsService {
  constructor(
    @InjectRepository(Mission)
    private readonly missions: Repository<Mission>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    private readonly publisher: TelemetryPublisher,
    private readonly incidents: FlightIncidentsService,
  ) {}

  async list(): Promise<PendingAlert[]> {
    const open = await this.missions.find({ where: { returnedAt: IsNull() } });
    if (!open.length) {
      return [];
    }
    const [orders, drones] = await Promise.all([
      this.orders.find({ where: { id: In(open.map((m) => m.orderId)) } }),
      this.drones.find({ where: { id: In(open.map((m) => m.droneId)) } }),
    ]);
    const orderById = new Map(orders.map((order) => [order.id, order]));
    const droneById = new Map(drones.map((drone) => [drone.id, drone]));
    const landings = await this.incidents.openLandings(
      open.map((m) => m.droneId),
    );
    const alerts: PendingAlert[] = [];
    for (const mission of open) {
      const order = orderById.get(mission.orderId);
      const drone = droneById.get(mission.droneId);
      if (!order || !drone) {
        continue;
      }
      const landing = landings.get(drone.id);
      const grounded = landing?.orderId === mission.orderId;
      const kinds = pendingAlertKinds(mission, order, grounded);
      if (!kinds.length) {
        continue;
      }
      if (grounded && landing?.landingLatitude != null) {
        // RF-34: la telemetría del pedido ya puede ser del dron nuevo.
        alerts.push({
          orderId: order.id,
          droneId: drone.id,
          identifier: drone.identifier,
          hubId: drone.hubId,
          kinds,
          latitude: landing.landingLatitude,
          longitude: landing.landingLongitude,
        });
        continue;
      }
      const flight = await this.publisher.readFlight(order.id);
      alerts.push({
        orderId: order.id,
        droneId: drone.id,
        identifier: drone.identifier,
        hubId: drone.hubId,
        kinds,
        latitude: flight?.latitude ?? null,
        longitude: flight?.longitude ?? null,
      });
    }
    return alerts;
  }
}
