import { simClock } from '../common/clock/sim-clock';
import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { IncidentOutcome } from '../common/enums/incident-outcome.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { QuarantineReason } from '../common/enums/quarantine-reason.enum';
import { ReturnOutcome } from '../common/enums/return-outcome.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneMaintenance } from '../fleet/drone-maintenance.entity';
import { Hub } from '../hubs/hub.entity';
import { QuarantineRecord } from '../inventory/quarantine-record.entity';
import { Order } from '../orders/order.entity';
import { FlightIncident } from './flight-incident.entity';
import {
  CRASH_REASON,
  FlightIncidentsService,
  LOST_REASON,
  RESCUE_MAINTENANCE_REASON,
  presentIncident,
} from './flight-incidents.service';

const NOW = new Date('2026-11-06T15:00:00.000Z');

function incident(overrides: Partial<FlightIncident> = {}): FlightIncident {
  return {
    id: 'incident-1',
    orderId: 'order-1',
    droneId: 'drone-1',
    hubId: 'hub-1',
    kind: IncidentKind.BATTERY_CRITICAL,
    severity: 'major',
    leg: RouteLeg.OUTBOUND,
    protocol: ContingencyProtocol.EMERGENCY_LANDING,
    outcome: IncidentOutcome.GROUNDED,
    latitude: 10.47,
    longitude: -73.25,
    batteryPercent: 4,
    landingLatitude: 10.47,
    landingLongitude: -73.25,
    rescueDueAt: new Date(NOW.getTime() - 1),
    packageMedication: 'Insulina',
    packageSaleType: 'otc' as never,
    packageQuantity: 2,
    packageLot: 'L-0001',
    packageLotExpiresOn: '2027-01-01',
    occurredAt: new Date(NOW.getTime() - 30 * 60_000),
    resolvedAt: null,
    ...overrides,
  };
}

function build(
  options: {
    row?: FlightIncident;
    order?: Partial<Order>;
  } = {},
) {
  const row = options.row ?? incident();
  const drone = {
    id: 'drone-1',
    status: DroneStatus.GROUNDED,
    flightsSinceMaintenance: 7,
  };
  const order = {
    id: 'order-1',
    status: OrderStatus.RECEIVED,
    droneId: null,
    ...options.order,
  };
  const saved: Array<{ entity: unknown; row: Record<string, unknown> }> = [];
  const manager = {
    findOne: jest.fn((entity: unknown) => {
      if (entity === FlightIncident) return Promise.resolve(row);
      if (entity === Drone) return Promise.resolve(drone);
      if (entity === Order) return Promise.resolve(order);
      return Promise.resolve(null);
    }),
    create: jest.fn((entity: unknown, data: Record<string, unknown>) => ({
      __entity: entity,
      ...data,
    })),
    save: jest.fn((value: Record<string, unknown>) => {
      saved.push({ entity: value.__entity, row: value });
      return Promise.resolve(value);
    }),
    update: jest.fn().mockResolvedValue(undefined),
  };
  const repo = {
    find: jest.fn().mockResolvedValue([row]),
    findOne: jest.fn().mockResolvedValue(row),
    save: jest.fn((value: FlightIncident) => Promise.resolve(value)),
    create: jest.fn((value: object) => ({ ...value, id: 'incident-1' })),
  };
  const hubRepo = {
    findOne: jest.fn().mockResolvedValue({
      id: 'hub-1',
      latitude: 10.46,
      longitude: -73.25,
    }),
  };
  const dataSource = {
    transaction: jest.fn((work: (m: typeof manager) => unknown) =>
      work(manager),
    ),
    getRepository: jest.fn((entity: unknown) =>
      entity === Hub ? hubRepo : repo,
    ),
  };
  const notifications = {
    incident: jest.fn().mockResolvedValue(undefined),
    statusChanged: jest.fn().mockResolvedValue(undefined),
  };
  const service = new FlightIncidentsService(
    dataSource as never,
    notifications as never,
  );
  return { service, manager, saved, drone, order, notifications, repo, row };
}

describe('Rescate del dron en tierra (RF-34, decisión del 2026-11-06)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('el rescate se programa según la distancia a la central', async () => {
    const { service, repo } = build({
      row: incident({ outcome: IncidentOutcome.LANDING, rescueDueAt: null }),
    });
    // 6 km al norte de la central: 12 min de camino y 10 de recoger.
    const landing = { latitude: 10.46 + 6 / 110.574, longitude: -73.25 };
    const grounded = await service.grounded('incident-1', landing);
    expect(grounded?.outcome).toBe(IncidentOutcome.GROUNDED);
    const minutes =
      ((grounded?.rescueDueAt?.getTime() ?? 0) - NOW.getTime()) / 60_000;
    expect(minutes).toBeCloseTo(22, 0);
    expect(repo.save).toHaveBeenCalled();
  });

  it('al llegar, el dron entra a mantenimiento y su paquete a cuarentena', async () => {
    const { service, saved, drone, manager, notifications } = build();
    await expect(service.rescueDue(NOW)).resolves.toBe(1);
    expect(drone.status).toBe(DroneStatus.MAINTENANCE);
    const maintenance = saved.find((s) => s.entity === DroneMaintenance);
    expect(maintenance?.row).toMatchObject({
      droneId: 'drone-1',
      kind: DroneMaintenanceKind.MAINTENANCE,
      reason: RESCUE_MAINTENANCE_REASON,
      openedByUserId: null,
      flightsAtStart: 7,
    });
    const quarantine = saved.find((s) => s.entity === QuarantineRecord);
    expect(quarantine?.row).toMatchObject({
      orderId: 'order-1',
      hubId: 'hub-1',
      lot: 'L-0001',
      quantity: 2,
      reason: QuarantineReason.INCIDENT,
    });
    expect(manager.update).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ orderId: 'order-1', droneId: 'drone-1' }),
      { returnedAt: NOW },
    );
    // El pedido ya salió con otro dron: no se toca.
    expect(notifications.statusChanged).not.toHaveBeenCalled();
    expect(notifications.incident).toHaveBeenCalledWith(
      expect.objectContaining({ outcome: IncidentOutcome.RESCUED }),
    );
  });

  it('si volvía con el paquete tras no retirarlo, el pedido llega con el rescate, ya en cuarentena', async () => {
    const { service, order, notifications } = build({
      order: { status: OrderStatus.RETURNING, droneId: 'drone-1' },
    });
    await service.rescueDue(NOW);
    expect(order).toMatchObject({
      status: OrderStatus.RETURNED,
      returnOutcome: ReturnOutcome.QUARANTINED,
    });
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      'order-1',
      OrderStatus.RETURNED,
    );
  });

  it('un dron que volvía vacío no deja cuarentena', async () => {
    const { service, saved } = build({
      row: incident({ packageQuantity: null, packageMedication: null }),
    });
    await service.rescueDue(NOW);
    expect(saved.some((s) => s.entity === QuarantineRecord)).toBe(false);
  });

  it('lo que se publica no lleva el medicamento (RNF-05)', async () => {
    const { service, notifications } = build();
    await service.rescueDue(NOW);
    const [published] = notifications.incident.mock.calls[0] as [object];
    expect(JSON.stringify(published)).not.toContain('Insulina');
    expect(published).toMatchObject({ packageOnBoard: true });
  });
});

describe('Choque grave y dron perdido: el paquete se pierde (RF-34)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('tras un choque grave lo recuperan, pero queda fuera de servicio y sin cuarentena', async () => {
    const { service, saved, drone } = build({
      row: incident({
        kind: IncidentKind.COLLISION_MAJOR,
        protocol: ContingencyProtocol.CRASH,
      }),
    });
    await service.rescueDue(NOW);
    expect(drone.status).toBe(DroneStatus.OUT_OF_SERVICE);
    expect(saved.find((s) => s.entity === DroneMaintenance)?.row).toMatchObject(
      {
        kind: DroneMaintenanceKind.OUT_OF_SERVICE,
        reason: CRASH_REASON,
      },
    );
    expect(saved.some((s) => s.entity === QuarantineRecord)).toBe(false);
  });

  it('dron perdido: fuera de servicio ya; si volvía con el paquete, el pedido cierra como perdido', async () => {
    const { service, saved, drone, order, notifications } = build({
      row: incident({
        kind: IncidentKind.DRONE_LOST,
        protocol: ContingencyProtocol.LOST,
        outcome: IncidentOutcome.LOST,
      }),
      order: { status: OrderStatus.RETURNING, droneId: 'drone-1' },
    });
    drone.status = DroneStatus.IN_MISSION;
    await expect(service.lose('incident-1')).resolves.toBe(true);
    expect(drone.status).toBe(DroneStatus.OUT_OF_SERVICE);
    expect(saved.find((s) => s.entity === DroneMaintenance)?.row).toMatchObject(
      { reason: LOST_REASON },
    );
    expect(saved.some((s) => s.entity === QuarantineRecord)).toBe(false);
    expect(order).toMatchObject({
      status: OrderStatus.RETURNED,
      returnOutcome: ReturnOutcome.LOST,
    });
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      'order-1',
      OrderStatus.RETURNED,
    );
  });

  it('lo que se publica dice si el paquete se perdió', () => {
    const lost = presentIncident(incident({ kind: IncidentKind.DRONE_LOST }));
    expect(lost).toMatchObject({ packageOnBoard: true, packageLost: true });
    expect(presentIncident(incident())).toMatchObject({ packageLost: false });
  });
});

describe('Incidentes abiertos para el mapa del operador', () => {
  it('pide solo los sin resolver de esas centrales, el más reciente primero', async () => {
    const { service, repo } = build({
      row: incident({ outcome: IncidentOutcome.GROUNDED, resolvedAt: null }),
    });
    await service.openForHubs(['hub-1', 'hub-2']);
    const [query] = repo.find.mock.calls[0] as [
      {
        where: {
          hubId: { value: string[] };
          resolvedAt: { type: string };
        };
        order: Record<string, string>;
      },
    ];
    expect(query.where.hubId.value).toEqual(['hub-1', 'hub-2']);
    expect(query.where.resolvedAt.type).toBe('isNull');
    expect(query.order).toEqual({ occurredAt: 'DESC' });
  });

  it('un resuelto no sale (la base lo filtra por resolvedAt)', async () => {
    const { service, repo } = build();
    repo.find.mockResolvedValueOnce([]);
    await expect(service.openForHubs(['hub-1'])).resolves.toEqual([]);
  });

  it('sin centrales no consulta la base', async () => {
    const { service, repo } = build();
    await expect(service.openForHubs([])).resolves.toEqual([]);
    expect(repo.find).not.toHaveBeenCalled();
  });

  it('no manda el medicamento, el lote ni la cantidad (RNF-05)', async () => {
    const { service } = build({ row: incident({ resolvedAt: null }) });
    const [open] = await service.openForHubs(['hub-1']);
    expect(open).toMatchObject({
      hubId: 'hub-1',
      kind: IncidentKind.BATTERY_CRITICAL,
      packageOnBoard: true,
      packageLost: false,
    });
    for (const key of ['packageMedication', 'packageLot', 'packageQuantity']) {
      expect(open).not.toHaveProperty(key);
    }
    const json = JSON.stringify(open);
    expect(json).not.toContain('Insulina');
    expect(json).not.toContain('L-0001');
  });
});
