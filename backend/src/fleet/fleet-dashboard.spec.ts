import { ForbiddenException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { resolvePeriod } from '../analytics/analytics.rules';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { NO_CORRIDOR } from '../decision/decision.rules';
import { NO_CORRIDOR_NOTE } from '../decision/decision-trace.rules';
import { DecisionTrace, HubTrace } from '../orders/order.entity';
import { DESTINATION_IN_GEOFENCE } from '../routing/routing.rules';
import { User } from '../users/user.entity';
import {
  DashboardDrone,
  DashboardFacts,
  DashboardFlight,
  blockedByGeofence,
  buildFleetDashboard,
} from './fleet-dashboard.rules';
import { FleetDashboardService } from './fleet-dashboard.service';

const HUB_A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

/** Periodo de 10 días que ya terminó: 100 % es 10 días de un dron. */
const period = resolvePeriod('2026-10-01', '2026-10-10');
const NOW = new Date('2026-11-05T17:00:00.000Z');
const HOUR = 3_600_000;
const DAY = 24 * HOUR;
const at = (hours: number) => new Date(period.from.getTime() + hours * HOUR);

function drone(overrides: Partial<DashboardDrone> = {}): DashboardDrone {
  return {
    id: 'd1',
    identifier: 'WG-198-001',
    hubId: HUB_A,
    status: DroneStatus.AVAILABLE,
    batteryPercent: 88,
    flightsSinceMaintenance: 12,
    maintenanceUntil: null,
    createdAt: new Date('2026-09-01T00:00:00.000Z'),
    ...overrides,
  };
}

function flight(overrides: Partial<DashboardFlight> = {}): DashboardFlight {
  return {
    droneId: 'd1',
    startedAt: at(10),
    returnedAt: at(11),
    km: 4.8,
    landingBatteryPercent: 70,
    batteryAlert: false,
    failureAlert: false,
    coldChainAlert: false,
    returnedWithPackage: false,
    latitude: 10.4802,
    longitude: -73.2401,
    ...overrides,
  };
}

function facts(overrides: Partial<DashboardFacts> = {}): DashboardFacts {
  return {
    period,
    now: NOW,
    drones: [drone()],
    flights: [],
    maintenance: [],
    geofenceBlocks: [],
    ...overrides,
  };
}

describe('Dashboard del operador: uso y disponibilidad', () => {
  it('reparte el tiempo de cada dron entre misión, taller y disponible', () => {
    const dashboard = buildFleetDashboard(
      facts({
        // 24 h de vuelo (10 %) y 2 días de taller (20 %) en 10 días.
        flights: [
          flight({ startedAt: at(0), returnedAt: at(12) }),
          flight({ startedAt: at(24), returnedAt: at(36) }),
        ],
        maintenance: [
          {
            droneId: 'd1',
            kind: DroneMaintenanceKind.MAINTENANCE,
            startedAt: at(48),
            closedAt: at(96),
          },
        ],
      }),
    );
    expect(dashboard.usage).toMatchObject({
      flights: 2,
      km: 9.6,
      inMissionPercent: 10,
      inShopPercent: 20,
      availablePercent: 70,
    });
    expect(dashboard.usage.byDrone[0]).toMatchObject({
      identifier: 'WG-198-001',
      flights: 2,
      inMissionPercent: 10,
      inShopPercent: 20,
    });
  });

  it('un taller que empezó antes del periodo solo cuenta su parte adentro', () => {
    const dashboard = buildFleetDashboard(
      facts({
        maintenance: [
          {
            droneId: 'd1',
            kind: DroneMaintenanceKind.OUT_OF_SERVICE,
            startedAt: new Date(period.from.getTime() - 5 * DAY),
            closedAt: at(24),
          },
        ],
      }),
    );
    expect(dashboard.usage.inShopPercent).toBe(10);
  });

  it('un dron dado de alta a mitad del periodo cuenta desde su alta', () => {
    const dashboard = buildFleetDashboard(
      facts({
        drones: [drone({ createdAt: at(5 * 24) })],
        // 12 h de vuelo en los 5 días que existió: 10 %.
        flights: [
          flight({ startedAt: at(5 * 24), returnedAt: at(5 * 24 + 12) }),
        ],
      }),
    );
    expect(dashboard.usage.inMissionPercent).toBe(10);
  });

  it('un vuelo que sigue en el aire cuenta hasta ahora', () => {
    const live = resolvePeriod('2026-11-05', '2026-11-05');
    const dashboard = buildFleetDashboard(
      facts({
        period: live,
        drones: [drone()],
        // Despegó a las 7:00 (Colombia); son las 12:00: 5 h de 12 h del día.
        flights: [
          flight({
            startedAt: new Date('2026-11-05T12:00:00.000Z'),
            returnedAt: null,
          }),
        ],
      }),
    );
    expect(dashboard.usage.inMissionPercent).toBeCloseTo(41.7, 1);
  });

  it('sin drones, nada divide por cero', () => {
    const dashboard = buildFleetDashboard(facts({ drones: [] }));
    expect(dashboard.usage).toMatchObject({
      flights: 0,
      inMissionPercent: 0,
      availablePercent: 0,
      byDrone: [],
    });
  });
});

describe('Dashboard del operador: salud de la flota', () => {
  it('resume la batería al volver y marca revisión y vencidos', () => {
    const dashboard = buildFleetDashboard(
      facts({
        drones: [
          drone({ flightsSinceMaintenance: 50 }),
          drone({
            id: 'd2',
            identifier: 'WG-198-002',
            status: DroneStatus.MAINTENANCE,
            maintenanceUntil: '2026-11-01',
          }),
        ],
        flights: [
          flight({ landingBatteryPercent: 62 }),
          flight({ landingBatteryPercent: 48 }),
          flight({ droneId: 'd2', landingBatteryPercent: null }),
        ],
      }),
    );
    expect(dashboard.health.landingBattery).toEqual({
      average: 55,
      min: 48,
      samples: 2,
    });
    expect(dashboard.health.maintenanceDue).toBe(1);
    expect(dashboard.health.maintenanceOverdue).toBe(1);
    expect(dashboard.health.byDrone[0]).toMatchObject({
      flightsSinceMaintenance: 50,
      maintenanceCycles: 50,
      maintenanceDue: true,
      landingBattery: { average: 55, min: 48, samples: 2 },
    });
    expect(dashboard.health.byDrone[1].landingBattery).toEqual({
      average: null,
      min: null,
      samples: 0,
    });
  });
});

describe('Dashboard del operador: alertas e incidentes', () => {
  it('cuenta las alertas por dron y por día, y los retornos con paquete', () => {
    const dashboard = buildFleetDashboard(
      facts({
        drones: [drone(), drone({ id: 'd2', identifier: 'WG-198-002' })],
        flights: [
          flight({ startedAt: at(10), batteryAlert: true }),
          flight({ startedAt: at(12), coldChainAlert: true }),
          flight({ startedAt: at(30), returnedWithPackage: true }),
          flight({ droneId: 'd2', startedAt: at(30) }),
        ],
      }),
    );
    expect(dashboard.incidents).toMatchObject({
      battery: 1,
      failure: 0,
      coldChain: 1,
      returnedWithPackage: 1,
    });
    // El dron sin incidentes no aparece en la lista.
    expect(dashboard.incidents.byDrone).toEqual([
      {
        droneId: 'd1',
        identifier: 'WG-198-001',
        battery: 1,
        failure: 0,
        coldChain: 1,
        returnedWithPackage: 1,
      },
    ]);
    expect(dashboard.incidents.byDay).toEqual([
      {
        date: '2026-10-01',
        flights: 2,
        battery: 1,
        failure: 0,
        coldChain: 1,
        returnedWithPackage: 0,
      },
      {
        date: '2026-10-02',
        flights: 2,
        battery: 0,
        failure: 0,
        coldChain: 0,
        returnedWithPackage: 1,
      },
    ]);
  });
});

describe('Dashboard del operador: zonas y geovallas', () => {
  it('una zona sale con 3 vuelos o más; con menos, no se revela', () => {
    const near = { latitude: 10.4802, longitude: -73.2401 };
    const lonely = { latitude: 10.5, longitude: -73.3 };
    const dashboard = buildFleetDashboard(
      facts({
        flights: [
          flight(near),
          flight(near),
          flight(near),
          flight(lonely),
          flight({ latitude: null, longitude: null }),
        ],
      }),
    );
    expect(dashboard.zones.flights).toEqual([
      { latitude: 10.485, longitude: -73.245, count: 3 },
    ]);
  });

  it('las geovallas cuentan todas, pero solo muestran zonas de 3 o más', () => {
    const point = { latitude: 10.47, longitude: -73.25 };
    const dashboard = buildFleetDashboard(
      facts({
        geofenceBlocks: [point, point, { latitude: 10.6, longitude: -73.1 }],
      }),
    );
    expect(dashboard.zones.geofenceBlocks).toEqual({ total: 3, zones: [] });
  });
});

describe('blockedByGeofence', () => {
  const hub = (overrides: Partial<HubTrace> = {}): HubTrace => ({
    hubId: HUB_A,
    name: 'Hospital Rosario Pumarejo',
    lot: true,
    corridorKm: null,
    etaMin: null,
    batteryNeededPercent: null,
    inRange: false,
    note: null,
    drones: [],
    ...overrides,
  });
  const trace = (hubs: HubTrace[]): DecisionTrace => ({
    at: '2026-10-02T15:00:00.000Z',
    outcome: 'conventional',
    reason: null,
    hubs,
  });
  const order = (
    overrides: Partial<Parameters<typeof blockedByGeofence>[0]> = {},
  ) => ({
    status: OrderStatus.REASSIGNED,
    statusReason: null,
    originHubId: null,
    decisionTrace: trace([hub({ note: NO_CORRIDOR_NOTE })]),
    ...overrides,
  });

  it('cuenta una central del operador sin corredor', () => {
    expect(blockedByGeofence(order(), [HUB_A])).toBe(true);
  });

  it('cuenta un dron descartado porque una geovalla tapa el corredor', () => {
    const blocked = order({
      decisionTrace: trace([
        hub({
          drones: [
            {
              identifier: 'WG-198-001',
              status: 'discarded',
              reason: NO_CORRIDOR,
              preempts: false,
              batteryPercent: 90,
            },
          ],
        }),
      ]),
    });
    expect(blockedByGeofence(blocked, [HUB_A])).toBe(true);
  });

  it('no cuenta la central sin corredor de otro operador', () => {
    expect(blockedByGeofence(order(), [HUB_B])).toBe(false);
  });

  it('no cuenta una central que se quedó sin lote, no sin corredor', () => {
    const noLot = order({
      decisionTrace: trace([hub({ note: 'No tiene un lote vigente.' })]),
    });
    expect(blockedByGeofence(noLot, [HUB_A])).toBe(false);
  });

  it('cuenta el destino rechazado dentro de una geovalla si salía de su central', () => {
    const rejected = order({
      status: OrderStatus.REJECTED,
      statusReason: DESTINATION_IN_GEOFENCE,
      originHubId: HUB_A,
      decisionTrace: trace([]),
    });
    expect(blockedByGeofence(rejected, [HUB_A])).toBe(true);
    expect(blockedByGeofence(rejected, [HUB_B])).toBe(false);
  });
});

describe('FleetDashboardService', () => {
  const operator = {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    role: UserRole.FLEET_OPERATOR,
    hubAssignments: [{ hubId: HUB_A }],
  } as unknown as User;

  function build() {
    const repos = {
      drones: { find: jest.fn().mockResolvedValue([]) },
      missions: { find: jest.fn().mockResolvedValue([]) },
      orders: { find: jest.fn().mockResolvedValue([]) },
      maintenance: { find: jest.fn().mockResolvedValue([]) },
    };
    const dataSource = {
      getRepository: jest.fn((entity: { name: string }) => {
        const byName: Record<string, object> = {
          Drone: repos.drones,
          Mission: repos.missions,
          Order: repos.orders,
          DroneMaintenance: repos.maintenance,
        };
        return byName[entity.name];
      }),
      query: jest.fn().mockResolvedValue([]),
    };
    const service = new FleetDashboardService(
      dataSource as unknown as DataSource,
    );
    return { service, repos };
  }

  it('una central que no es suya responde 403', async () => {
    const { service, repos } = build();
    await expect(
      service.dashboard(operator, { hubId: HUB_B }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(repos.drones.find).not.toHaveBeenCalled();
  });

  it('un periodo al revés responde 400 con el mensaje de analytics', async () => {
    const { service } = build();
    await expect(
      service.dashboard(operator, { from: '2026-10-10', to: '2026-10-01' }),
    ).rejects.toThrow('La fecha inicial');
  });

  it('del pedido solo lee estado, alerta de frío y la traza: nada clínico', async () => {
    const { service, repos } = build();
    repos.drones.find.mockResolvedValue([
      {
        id: 'd1',
        identifier: 'WG-198-001',
        hubId: HUB_A,
        status: DroneStatus.AVAILABLE,
        batteryPercent: 90,
        batteryUpdatedAt: null,
        flightsSinceMaintenance: 3,
        maintenanceUntil: null,
        createdAt: new Date('2026-09-01T00:00:00.000Z'),
      },
    ]);
    repos.missions.find.mockResolvedValue([
      {
        orderId: 'o1',
        droneId: 'd1',
        startedAt: at(10),
        returnedAt: at(11),
        landingBatteryPercent: 64,
        batteryAlert: false,
        failureAlert: false,
      },
    ]);
    await service.dashboard(operator, { from: '2026-10-01', to: '2026-10-10' });
    for (const [query] of repos.orders.find.mock.calls as Array<
      [{ select: Record<string, boolean> }]
    >) {
      expect(query.select).not.toHaveProperty('medicationName');
      expect(query.select).not.toHaveProperty('requesterId');
      expect(query.select).not.toHaveProperty('address');
    }
  });
});
