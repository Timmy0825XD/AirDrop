import { DaylightService } from '../airspace/daylight.service';
import { DEFAULT_DELIVERY_WAIT_MS } from '../delivery/delivery.rules';
import { TerrainService } from '../airspace/terrain.service';
import { climbPercentPerM } from '../airspace/terrain.rules';
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
import { batteryNow } from '../simulation/flight-energy.rules';
import {
  DESCENT_MS,
  LANDING_MS,
  RELAY_SWAP_MS,
  TAKEOFF_MS,
  TRANSITION_MS,
} from '../simulation/simulation.rules';
import {
  CRITICAL_BATTERY_PERCENT,
  legBatteryPercent,
} from '../simulation/flight-energy.rules';
import { NODES } from '../airspace/regional-network';
import { HubStatus } from '../common/enums/hub-status.enum';
import { reverseCorridor } from '../routing/routing.rules';
import { corridorWeather, windLimitsOf } from '../weather/weather.rules';
import { WeatherService } from '../weather/weather.service';
import {
  CandidateTerrain,
  DroneCandidate,
  chooseDrone,
  missionWithClimbPercent,
  payloadKgOf,
} from './decision.rules';
import { EligibilityService } from './eligibility.service';
import { simClock } from '../common/clock/sim-clock';

export type HubEvaluation = {
  lot: InventoryItem | null;
  drones: Drone[];
  modelsById: Map<string, DroneModel>;
  corridor: PlannedCorridor | null;
  choice: ReturnType<typeof chooseDrone>;
  /** Duración de la ida por el corredor con el modelo de la central. */
  etaMs: number | null;
  /** RF-11: la batería llena alcanza ida, regreso y reserva por ese corredor. */
  inRange: boolean;
  /** Batería de cada dron ahora, con lo que recargó en tierra. */
  batteryByDrone: Map<string, number>;
  /** RF-32: km que "cuesta" el crucero con el clima (ida y regreso, promedio). */
  energyKm: number | null;
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
    private readonly weather: WeatherService,
    private readonly terrain: TerrainService,
    private readonly daylight: DaylightService,
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
        etaMs: null,
        inRange: false,
        batteryByDrone: new Map(),
        energyKm: null,
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
    const now = simClock.now();
    const batteryByDrone = new Map(
      drones.map((drone) => [
        drone.id,
        batteryNow(
          drone.batteryPercent ?? 100,
          drone.batteryUpdatedAt ?? null,
          now,
        ),
      ]),
    );
    const destination = {
      longitude: order.longitude as number,
      latitude: order.latitude as number,
    };
    const corridor = this.routes.plan(
      { longitude: hub.longitude, latitude: hub.latitude },
      destination,
      polygons,
    );
    // RF-32: el clima del corredor de ida y del regreso por el mismo camino,
    // para cada tipo: su crucero cambia los km equivalentes y su límite de
    // viento decide si vuela.
    const cells = this.weather.active(now);
    const weatherByModel = new Map(
      [...modelsById.values()].map((model) => [
        model.id,
        modelWeather(corridor, cells, model),
      ]),
    );
    // RF-46: el perfil del terreno de ida y de regreso para cada tipo (su
    // velocidad vertical decide cuándo empieza a subir).
    const terrainByModel = new Map(
      [...modelsById.values()].map((model) => [
        model.id,
        corridor ? this.missionTerrain(corridor, model) : undefined,
      ]),
    );
    // RF-44: ida, espera del código y regreso, con el crucero de cada tipo,
    // tienen que caber entre la salida y la puesta del sol del nodo.
    const daylightByModel = new Map(
      [...modelsById.values()].map((model) => [
        model.id,
        this.daylight.fits(
          now,
          { latitude: hub.latitude, longitude: hub.longitude },
          missionMs(
            corridor,
            model,
            weatherByModel.get(model.id)?.there?.cruiseMs ?? null,
          ),
        ),
      ]),
    );
    const choice = this.eligibility.choose({
      missionType: order.missionType,
      quantity: order.quantity,
      payloadKg: payloadKgOf(lot, order.quantity),
      requiresCold: order.requiresColdChain,
      weatherFlyable: true,
      candidates: drones.flatMap((drone) => {
        const model = modelsById.get(drone.droneModelId);
        const weather = weatherByModel.get(drone.droneModelId);
        if (!model || !weather) {
          return [];
        }
        return [
          {
            drone: toCandidate(
              drone,
              model,
              heldByDrone.get(drone.id) ?? null,
              batteryByDrone.get(drone.id) ?? 100,
            ),
            distanceKm: weather.energyKm,
            weather: { flyable: weather.flyable, reason: weather.reason },
            terrain: terrainByModel.get(drone.droneModelId),
            daylight: daylightByModel.get(drone.droneModelId) ?? true,
          },
        ];
      }),
    });
    const chosenDrone = drones.find(
      (drone) => drone.id === choice.chosen?.droneId,
    );
    // La llegada y el alcance de la central: los del dron elegido o, si no
    // hay, los del tipo de más alcance (la central "podría" con él).
    const model =
      modelsById.get(chosenDrone?.droneModelId ?? '') ??
      [...modelsById.values()].sort((a, b) => b.maxRangeKm - a.maxRangeKm)[0];
    const there = model ? weatherByModel.get(model.id)?.there : null;
    const energyKm = model
      ? (weatherByModel.get(model.id)?.energyKm ?? null)
      : (corridor?.distanceKm ?? null);
    const reach =
      corridor && model
        ? {
            // La ida con el viento que hay: el crucero puede tardar más.
            etaMs:
              TAKEOFF_MS +
              TRANSITION_MS +
              (there?.cruiseMs ??
                (corridor.distanceKm / model.maxSpeedKmh) * 3_600_000) +
              DESCENT_MS +
              LANDING_MS,
            inRange:
              missionWithClimbPercent(
                energyKm ?? corridor.distanceKm,
                {
                  maxRangeKm: model.maxRangeKm,
                  climbPercentPerM: climbPercentPerM(model),
                },
                terrainByModel.get(model.id),
              ) <= 100,
          }
        : { etaMs: null, inRange: false };
    const direct: HubEvaluation = {
      lot,
      drones,
      modelsById,
      corridor,
      choice,
      ...reach,
      batteryByDrone,
      energyKm,
    };
    if (choice.chosen) {
      return direct;
    }
    // RF-55: si ningún dron llega en un solo tramo, se prueba la escala.
    const relay = await this.relayHub(manager, hub);
    if (!relay) {
      return direct;
    }
    const withRelay = this.evaluateRelay({
      hub,
      relay,
      destination,
      order,
      lot,
      drones,
      modelsById,
      heldByDrone,
      batteryByDrone,
      polygons,
      now,
    });
    return withRelay?.choice.chosen ? withRelay : direct;
  }

  /** RF-55: el Nodo Valledupar, activo y distinto de la central que evalúa. */
  private async relayHub(
    manager: EntityManager,
    hub: Hub,
  ): Promise<Hub | null> {
    if (hub.name === NODES.valledupar.name) {
      return null;
    }
    return manager.findOne(Hub, {
      where: { name: NODES.valledupar.name, status: HubStatus.ACTIVE },
    });
  }

  /**
   * RF-55: la misión con escala. El tramo nodo → relevo sale con la batería
   * que el dron tiene ahora; relevo → destino → relevo, con la batería nueva;
   * el regreso relevo → nodo, con otra nueva. Cada uno cierra con la reserva.
   */
  private evaluateRelay(input: {
    hub: Hub;
    relay: Hub;
    destination: { latitude: number; longitude: number };
    order: Order;
    lot: InventoryItem;
    drones: Drone[];
    modelsById: Map<string, DroneModel>;
    heldByDrone: Map<string, Order>;
    batteryByDrone: Map<string, number>;
    polygons: GeoJsonPolygon[];
    now: Date;
  }): HubEvaluation | null {
    const origin = {
      latitude: input.hub.latitude,
      longitude: input.hub.longitude,
    };
    const relayPoint = {
      latitude: input.relay.latitude,
      longitude: input.relay.longitude,
    };
    const toRelay = this.routes.plan(origin, relayPoint, input.polygons);
    const fromRelay = toRelay
      ? this.routes.plan(relayPoint, input.destination, input.polygons)
      : null;
    const corridor = this.routes.planWithRelay(
      origin,
      relayPoint,
      input.destination,
      input.polygons,
    );
    if (!toRelay || !fromRelay || !corridor) {
      return null;
    }
    const cells = this.weather.active(input.now);
    const perModel = new Map(
      [...input.modelsById.values()].map((model) => {
        const first = modelWeather(toRelay, cells, model);
        const second = modelWeather(fromRelay, cells, model);
        const firstTerrain = this.terrain.profile(toRelay, model);
        const secondTerrain = this.missionTerrain(fromRelay, model);
        // Lo que pide llegar al relevo con la batería de ahora.
        const firstPercent =
          legBatteryPercent(
            first.energyKm ?? toRelay.distanceKm,
            model.maxRangeKm,
          ) +
          firstTerrain.climbM * climbPercentPerM(model) +
          CRITICAL_BATTERY_PERCENT;
        const firstCruise = first.there?.cruiseMs ?? null;
        const secondCruise = second.there?.cruiseMs ?? null;
        const ms =
          missionMs(toRelay, model, firstCruise) -
          DEFAULT_DELIVERY_WAIT_MS +
          missionMs(fromRelay, model, secondCruise) +
          2 * RELAY_SWAP_MS;
        return [
          model.id,
          {
            flyable: first.flyable && second.flyable,
            reason: first.reason ?? second.reason,
            energyKm: second.energyKm,
            terrain: {
              climbM: secondTerrain.climbM,
              peakMslM: Math.max(secondTerrain.peakMslM, firstTerrain.peakMslM),
            },
            firstPercent,
            daylight: this.daylight.fits(input.now, origin, ms),
            etaMs:
              legMs(toRelay, model, firstCruise) +
              RELAY_SWAP_MS +
              legMs(fromRelay, model, secondCruise),
          },
        ] as const;
      }),
    );
    const choice = this.eligibility.choose({
      missionType: input.order.missionType,
      quantity: input.order.quantity,
      payloadKg: payloadKgOf(input.lot, input.order.quantity),
      requiresCold: input.order.requiresColdChain,
      weatherFlyable: true,
      candidates: input.drones.flatMap((drone) => {
        const model = input.modelsById.get(drone.droneModelId);
        const plan = perModel.get(drone.droneModelId);
        if (!model || !plan) {
          return [];
        }
        const battery = input.batteryByDrone.get(drone.id) ?? 100;
        return [
          {
            // Tras el cambio en el relevo vuela con batería llena; si no
            // alcanza a llegar al relevo, queda sin batería y se descarta.
            drone: toCandidate(
              drone,
              model,
              input.heldByDrone.get(drone.id) ?? null,
              battery >= plan.firstPercent ? 100 : 0,
            ),
            distanceKm: plan.energyKm,
            weather: { flyable: plan.flyable, reason: plan.reason },
            terrain: plan.terrain,
            daylight: plan.daylight,
          },
        ];
      }),
    });
    const chosen = input.drones.find(
      (drone) => drone.id === choice.chosen?.droneId,
    );
    const plan = chosen ? perModel.get(chosen.droneModelId) : undefined;
    return {
      lot: input.lot,
      drones: input.drones,
      modelsById: input.modelsById,
      corridor,
      choice,
      etaMs: plan?.etaMs ?? null,
      inRange: plan != null,
      batteryByDrone: input.batteryByDrone,
      energyKm: plan?.energyKm ?? null,
    };
  }

  /** Subida de ida y de regreso, y el punto más alto, para un tipo. */
  private missionTerrain(
    corridor: PlannedCorridor,
    model: DroneModel,
  ): CandidateTerrain {
    const out = this.terrain.profile(corridor, model);
    const back = this.terrain.profile(reverseCorridor(corridor), model);
    return {
      climbM: out.climbM + back.climbM,
      peakMslM: Math.max(out.peakMslM, back.peakMslM),
    };
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
      // salud.md: la mercancía peligrosa no viaja por dron.
      .andWhere('item.dangerousGoods = false')
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
  batteryPercent: number,
): DroneCandidate {
  return {
    batteryPercent,
    lastFlightEndedAt: drone.lastFlightEndedAt ?? null,
    id: drone.id,
    identifier: drone.identifier,
    status: drone.status,
    maxPayloadKg: model.maxPayloadKg,
    maxRangeKm: model.maxRangeKm,
    coldCompartment: drone.coldCompartment ?? false,
    cruiseKmh: model.maxSpeedKmh,
    batteryWh: model.batteryWh,
    ceilingM: model.ceilingM,
    climbPercentPerM: climbPercentPerM(model),
    held: held
      ? {
          orderId: held.id,
          missionType: held.missionType,
          status: held.status,
        }
      : null,
  };
}

/**
 * El clima de ida y de regreso para un tipo de dron. Sin celdas vigentes,
 * cuentan los km del corredor; sin corredor, no hay energía que medir.
 */
function modelWeather(
  corridor: PlannedCorridor | null,
  cells: ReturnType<WeatherService['active']>,
  model: DroneModel,
) {
  if (!corridor) {
    return { flyable: true, reason: null, energyKm: null, there: null };
  }
  if (!cells.length) {
    return {
      flyable: true,
      reason: null,
      energyKm: corridor.distanceKm,
      there: null,
    };
  }
  const limits = windLimitsOf(model);
  const there = corridorWeather(corridor, cells, model.maxSpeedKmh, limits);
  const back = corridorWeather(
    reverseCorridor(corridor),
    cells,
    model.maxSpeedKmh,
    limits,
  );
  return {
    flyable: there.flyable && back.flyable,
    reason: there.reason ?? back.reason,
    energyKm: Math.round(((there.energyKm + back.energyKm) / 2) * 100) / 100,
    there,
  };
}

/** Un tramo: despegue, crucero con el clima que haya, bajada y aterrizaje. */
function legMs(
  corridor: PlannedCorridor,
  model: DroneModel,
  cruiseMs: number | null,
): number {
  const cruise =
    cruiseMs ?? (corridor.distanceKm / model.maxSpeedKmh) * 3_600_000;
  return TAKEOFF_MS + TRANSITION_MS + cruise + DESCENT_MS + LANDING_MS;
}

/**
 * RF-44: lo que dura la misión completa para la ventana de luz: ida, espera
 * del código (5 min) y regreso por el mismo corredor.
 */
function missionMs(
  corridor: PlannedCorridor | null,
  model: DroneModel,
  cruiseMs: number | null,
): number {
  if (!corridor) {
    return 0;
  }
  const cruise =
    cruiseMs ?? (corridor.distanceKm / model.maxSpeedKmh) * 3_600_000;
  const leg = TAKEOFF_MS + TRANSITION_MS + cruise + DESCENT_MS + LANDING_MS;
  return 2 * leg + DEFAULT_DELIVERY_WAIT_MS;
}
