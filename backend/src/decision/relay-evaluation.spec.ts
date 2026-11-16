import { EntityManager } from 'typeorm';
import { ALWAYS_DAY } from '../airspace/daylight.testing';
import { FLAT_TERRAIN } from '../airspace/terrain.testing';
import { AirspaceService } from '../airspace/airspace.service';
import { DELIVERY_POINTS, NODES } from '../airspace/regional-network';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { DRONE_TYPES } from '../fleet/drone-types';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { Order } from '../orders/order.entity';
import { RoutePlannerService } from '../routing/route-planner.service';
import { RELAY_NOTE, traceEvaluatedHub } from './decision-trace.rules';
import { EligibilityService } from './eligibility.service';
import { HubEvaluationService } from './hub-evaluation.service';

/**
 * RF-55 con la red real: el insumo está solo en Codazzi y el pedido va a
 * Patillal, a unos 70 km. Ningún tipo va y vuelve directo; con la escala en
 * el Nodo Valledupar, el Colibrí sí.
 */
const colibri = DRONE_TYPES.find((type) => type.name === 'Colibrí')!;
const patillal = DELIVERY_POINTS.find((point) => point.code === 'dp-patillal')!;

const codazzi = {
  id: 'hub-codazzi',
  name: NODES.codazzi.name,
  latitude: NODES.codazzi.latitude,
  longitude: NODES.codazzi.longitude,
  status: HubStatus.ACTIVE,
} as Hub;

const valledupar = {
  id: 'hub-valledupar',
  name: NODES.valledupar.name,
  latitude: NODES.valledupar.latitude,
  longitude: NODES.valledupar.longitude,
  status: HubStatus.ACTIVE,
} as Hub;

const model = { id: 'model-rapid', ...colibri };

function drone(battery: number): Drone {
  return {
    id: 'drone-1',
    identifier: 'AD-COD-01',
    hubId: codazzi.id,
    droneModelId: model.id,
    status: DroneStatus.AVAILABLE,
    coldCompartment: false,
    batteryPercent: battery,
    batteryUpdatedAt: null,
    lastFlightEndedAt: null,
  } as unknown as Drone;
}

const lot = {
  id: 'lot-1',
  hubId: codazzi.id,
  name: 'Acetaminofén 500 mg',
  quantity: 100,
  unitWeightG: 30,
} as unknown as InventoryItem;

const order = {
  id: 'order-1',
  medicationName: 'Acetaminofén 500 mg',
  quantity: 2,
  missionType: MissionType.EMERGENCY,
  requiresColdChain: false,
  latitude: patillal.latitude,
  longitude: patillal.longitude,
} as unknown as Order;

function build(
  options: {
    battery?: number;
    relayActive?: boolean;
    destination?: { latitude: number; longitude: number };
  } = {},
) {
  const builder = (answer: unknown) => {
    const chain: Record<string, jest.Mock> = {};
    for (const name of [
      'where',
      'andWhere',
      'orderBy',
      'addOrderBy',
      'setLock',
    ]) {
      chain[name] = jest.fn(() => chain);
    }
    chain.getOne = jest.fn(() => Promise.resolve(answer));
    chain.getMany = jest.fn(() => Promise.resolve(answer));
    return chain;
  };
  const manager = {
    createQueryBuilder: jest.fn((entity: unknown) =>
      entity === InventoryItem
        ? builder(lot)
        : builder([drone(options.battery ?? 100)]),
    ),
    find: jest.fn((entity: unknown) =>
      Promise.resolve(entity === DroneModel ? [model] : []),
    ),
    findOne: jest.fn((entity: unknown) =>
      Promise.resolve(
        entity === Hub && options.relayActive !== false ? valledupar : null,
      ),
    ),
  };
  const airspace = new AirspaceService();
  const routes = new RoutePlannerService(
    { manager: { query: jest.fn().mockResolvedValue([]) } } as never,
    { stormPolygons: () => [] } as never,
    airspace,
  );
  const service = new HubEvaluationService(
    routes,
    new EligibilityService(),
    { active: () => [] } as never,
    FLAT_TERRAIN,
    ALWAYS_DAY,
  );
  return {
    evaluate: () =>
      service.evaluate(
        manager as unknown as EntityManager,
        codazzi,
        { ...order, ...options.destination },
        '2026-11-16',
        airspace.blockingPolygons(),
        false,
      ),
  };
}

describe('Relevo en Valledupar (RF-55)', () => {
  it('sin alcance directo, elige el dron con escala en Valledupar', async () => {
    const evaluation = await build().evaluate();
    expect(evaluation.choice.chosen?.identifier).toBe('AD-COD-01');
    expect(evaluation.corridor?.relayKm).toBeGreaterThan(40);
    expect(evaluation.inRange).toBe(true);
    expect(traceEvaluatedHub(codazzi, evaluation).note).toBe(RELAY_NOTE);
  });

  it('sin batería para llegar al relevo, no sale', async () => {
    const evaluation = await build({ battery: 50 }).evaluate();
    expect(evaluation.choice.chosen).toBeNull();
    expect(evaluation.corridor?.relayKm ?? null).toBeNull();
  });

  it('con el Nodo Valledupar suspendido, no hay relevo', async () => {
    const evaluation = await build({ relayActive: false }).evaluate();
    expect(evaluation.choice.chosen).toBeNull();
  });

  it('si alcanza directo, va directo', async () => {
    const evaluation = await build({
      destination: { latitude: 10.03, longitude: -73.24 },
    }).evaluate();
    expect(evaluation.choice.chosen).not.toBeNull();
    expect(evaluation.corridor?.relayKm ?? null).toBeNull();
  });
});
