import { Injectable } from '@nestjs/common';
import { EntityManager, In } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { Order } from '../orders/order.entity';
import { PlannedCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import {
  DroneCandidate,
  chooseDrone,
  simulatedWeather,
} from './decision.rules';
import { EligibilityService } from './eligibility.service';

export type HubEvaluation = {
  lot: InventoryItem | null;
  drones: Drone[];
  modelsById: Map<string, DroneModel>;
  corridor: PlannedCorridor | null;
  choice: ReturnType<typeof chooseDrone>;
};

/**
 * Responde si una central puede despachar un pedido: lote vigente (FEFO),
 * corredor libre de geovallas y un dron elegible. No reserva nada.
 * Con `lock`, bloquea el lote y los drones para la autorización.
 */
@Injectable()
export class HubEvaluationService {
  constructor(
    private readonly routes: RoutePlannerService,
    private readonly eligibility: EligibilityService,
  ) {}

  async evaluate(
    manager: EntityManager,
    hub: Hub,
    order: Order,
    today: string,
    polygons: GeoJsonPolygon[],
    lock: boolean,
  ): Promise<HubEvaluation> {
    const lot = await this.findFefoLot(manager, hub.id, order, today, lock);
    if (!lot) {
      return {
        lot: null,
        drones: [],
        modelsById: new Map(),
        corridor: null,
        choice: { chosen: null, discarded: [] },
      };
    }
    const query = manager
      .createQueryBuilder(Drone, 'drone')
      .where('drone.hubId = :hubId', { hubId: hub.id })
      .orderBy('drone.id', 'ASC');
    const drones = await (
      lock ? query.setLock('pessimistic_write') : query
    ).getMany();
    const modelsById = await this.modelsById(manager, drones);
    const heldByDrone = await this.heldByDrone(manager, drones);
    const corridor = this.routes.plan(
      { longitude: hub.longitude, latitude: hub.latitude },
      {
        longitude: order.longitude as number,
        latitude: order.latitude as number,
      },
      polygons,
    );
    const choice = this.eligibility.choose({
      missionType: order.missionType,
      quantity: order.quantity,
      weatherFlyable: simulatedWeather().flyable,
      candidates: drones.flatMap((drone) => {
        const model = modelsById.get(drone.droneModelId);
        if (!model) {
          return [];
        }
        return [
          {
            drone: toCandidate(drone, model, heldByDrone.get(drone.id) ?? null),
            distanceKm: corridor?.distanceKm ?? null,
          },
        ];
      }),
    });
    return { lot, drones, modelsById, corridor, choice };
  }

  findFefoLot(
    manager: EntityManager,
    hubId: string,
    order: Order,
    today: string,
    lock: boolean,
  ): Promise<InventoryItem | null> {
    const query = manager
      .createQueryBuilder(InventoryItem, 'item')
      .where('item.hubId = :hubId', { hubId })
      .andWhere('LOWER(item.name) = :name', {
        name: order.medicationName.trim().toLowerCase(),
      })
      .andWhere('item.saleType = :saleType', { saleType: order.saleType })
      .andWhere('item.expirationDate >= :today', { today })
      .andWhere('item.quantity >= :quantity', { quantity: order.quantity })
      .orderBy('item.expirationDate', 'ASC')
      .addOrderBy('item.lot', 'ASC');
    return (lock ? query.setLock('pessimistic_write') : query).getOne();
  }

  private async modelsById(manager: EntityManager, drones: Drone[]) {
    const modelIds = [...new Set(drones.map((drone) => drone.droneModelId))];
    if (!modelIds.length) {
      return new Map<string, DroneModel>();
    }
    const models = await manager.find(DroneModel, {
      where: { id: In(modelIds) },
    });
    return new Map(models.map((model) => [model.id, model]));
  }

  private async heldByDrone(manager: EntityManager, drones: Drone[]) {
    const droneIds = drones.map((drone) => drone.id);
    if (!droneIds.length) {
      return new Map<string, Order>();
    }
    const held = await manager.find(Order, {
      where: { droneId: In(droneIds), status: OrderStatus.PENDING_LOAD },
    });
    return new Map(
      held
        .filter((order) => order.droneId)
        .map((order) => [order.droneId as string, order]),
    );
  }
}

function toCandidate(
  drone: Drone,
  model: DroneModel,
  held: Order | null,
): DroneCandidate {
  return {
    id: drone.id,
    identifier: drone.identifier,
    status: drone.status,
    maxPayloadKg: model.maxPayloadKg,
    maxRangeKm: model.maxRangeKm,
    held: held
      ? {
          orderId: held.id,
          missionType: held.missionType,
          status: held.status,
        }
      : null,
  };
}
