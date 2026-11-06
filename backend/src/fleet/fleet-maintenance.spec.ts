import { NotFoundException } from '@nestjs/common';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { HubsService } from '../hubs/hubs.service';
import { InboxService } from '../notifications/inbox.service';
import { User } from '../users/user.entity';
import { Drone } from './drone.entity';
import { DroneMaintenance } from './drone-maintenance.entity';
import { FleetService } from './fleet.service';
import { MaintenanceSweepService } from './maintenance-sweep.service';
import {
  DEFAULT_MAINTENANCE_CYCLES,
  isMaintenanceDue,
  isMaintenanceOverdue,
  maintenanceCycles,
} from './maintenance.rules';

const HUB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const DRONE_ID = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

/** 2026-11-05 a mediodía en Colombia. */
const NOW = new Date('2026-11-05T17:00:00.000Z');

const operator = {
  id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  role: UserRole.FLEET_OPERATOR,
  hubAssignments: [{ hubId: HUB }],
} as unknown as User;

function drone(overrides: Partial<Drone> = {}): Drone {
  return {
    id: DRONE_ID,
    identifier: 'WG-198-001',
    droneModelId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    hubId: HUB,
    status: DroneStatus.AVAILABLE,
    maintenanceReason: null,
    maintenanceUntil: null,
    flightsSinceMaintenance: 12,
    maintenanceDueNotifiedAt: null,
    maintenanceOverdueNotifiedAt: null,
    batteryPercent: 100,
    batteryUpdatedAt: null,
    lastFlightEndedAt: null,
    createdAt: new Date('2026-10-01T15:00:00.000Z'),
    ...overrides,
  } as Drone;
}

/** Repositorios en memoria: un dron y su historial de taller. */
function build(start: Drone = drone(), history: DroneMaintenance[] = []) {
  let current = { ...start };
  const periods = [...history];
  let nextId = 1;
  const drones = {
    findOne: jest.fn(() => Promise.resolve({ ...current })),
    save: jest.fn((row: Drone) => {
      current = { ...row };
      return Promise.resolve({ ...row });
    }),
  };
  const maintenances = {
    findOne: jest.fn(() =>
      Promise.resolve(periods.find((row) => row.closedAt === null) ?? null),
    ),
    find: jest.fn(() => Promise.resolve([...periods].reverse())),
    create: jest.fn((value: Partial<DroneMaintenance>) => ({
      ...value,
      id: `period-${nextId++}`,
      startedAt: NOW,
    })),
    save: jest.fn((row: DroneMaintenance) => {
      const index = periods.findIndex((period) => period.id === row.id);
      if (index >= 0) {
        periods[index] = row;
      } else {
        periods.push(row);
      }
      return Promise.resolve(row);
    }),
  };
  const service = new FleetService(
    drones as never,
    {} as never,
    maintenances as never,
    {} as HubsService,
  );
  return { service, periods, current: () => current };
}

describe('Mantenimiento y fuera de servicio (CU-16, CU-17)', () => {
  beforeAll(() => {
    jest.useFakeTimers({ now: NOW });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  it('registrar un mantenimiento deja el dron en mantenimiento y abre un periodo', async () => {
    const { service, periods } = build();
    const result = await service.registerMaintenance(operator, DRONE_ID, {
      reason: 'Cambio de hélices',
      estimatedEndDate: '2026-11-08',
    });
    expect(result).toMatchObject({
      status: DroneStatus.MAINTENANCE,
      maintenanceReason: 'Cambio de hélices',
      maintenanceUntil: '2026-11-08',
      maintenanceOverdue: false,
    });
    expect(periods).toEqual([
      expect.objectContaining({
        kind: DroneMaintenanceKind.MAINTENANCE,
        reason: 'Cambio de hélices',
        estimatedEndDate: '2026-11-08',
        flightsAtStart: 12,
        openedByUserId: operator.id,
        closedAt: null,
      }),
    ]);
  });

  it('cambiar la fecha de un mantenimiento abierto no abre otro periodo', async () => {
    const { service, periods } = build();
    await service.registerMaintenance(operator, DRONE_ID, {
      reason: 'Cambio de hélices',
      estimatedEndDate: '2026-11-08',
    });
    await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.MAINTENANCE,
      estimatedEndDate: '2026-11-12',
    });
    expect(periods).toHaveLength(1);
    expect(periods[0]).toMatchObject({
      reason: 'Cambio de hélices',
      estimatedEndDate: '2026-11-12',
    });
  });

  it('cerrar un mantenimiento deja el dron revisado: los vuelos vuelven a cero', async () => {
    const { service, periods } = build(
      drone({ maintenanceDueNotifiedAt: new Date('2026-11-01T00:00:00Z') }),
    );
    await service.registerMaintenance(operator, DRONE_ID, {
      reason: 'Revisión de los 50 vuelos',
      estimatedEndDate: '2026-11-06',
    });
    const result = await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.AVAILABLE,
    });
    expect(result).toMatchObject({
      status: DroneStatus.AVAILABLE,
      maintenanceReason: null,
      maintenanceUntil: null,
      flightsSinceMaintenance: 0,
      maintenanceDue: false,
    });
    expect(periods[0].closedAt).toEqual(NOW);
    expect(periods[0].closedByUserId).toBe(operator.id);
  });

  it('fuera de servicio es indefinido: no guarda fecha de fin', async () => {
    const { service, periods } = build();
    const result = await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.OUT_OF_SERVICE,
      reason: 'Motor dañado',
      estimatedEndDate: '2026-11-20',
    });
    expect(result.maintenanceUntil).toBeNull();
    expect(periods[0]).toMatchObject({
      kind: DroneMaintenanceKind.OUT_OF_SERVICE,
      estimatedEndDate: null,
    });
  });

  it('volver de fuera de servicio no cuenta como revisión', async () => {
    const { service } = build();
    await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.OUT_OF_SERVICE,
      reason: 'Motor dañado',
    });
    const result = await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.AVAILABLE,
    });
    expect(result.flightsSinceMaintenance).toBe(12);
  });

  it('pasar de mantenimiento a fuera de servicio cierra uno y abre el otro', async () => {
    const { service, periods } = build();
    await service.registerMaintenance(operator, DRONE_ID, {
      reason: 'Cambio de hélices',
      estimatedEndDate: '2026-11-08',
    });
    await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.OUT_OF_SERVICE,
      reason: 'Falla el motor',
    });
    expect(periods.map((period) => [period.kind, period.closedAt])).toEqual([
      [DroneMaintenanceKind.MAINTENANCE, NOW],
      [DroneMaintenanceKind.OUT_OF_SERVICE, null],
    ]);
  });

  it('un dron en mantenimiento desde antes del historial también se cierra bien', async () => {
    const { service, periods } = build(
      drone({
        status: DroneStatus.MAINTENANCE,
        maintenanceReason: 'Viejo',
        maintenanceUntil: '2026-11-01',
      }),
    );
    const result = await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.AVAILABLE,
    });
    expect(periods).toEqual([]);
    expect(result.flightsSinceMaintenance).toBe(0);
  });

  it('marca vencido el mantenimiento cuya fecha ya pasó', async () => {
    const { service } = build(
      drone({
        status: DroneStatus.MAINTENANCE,
        maintenanceUntil: '2026-11-04',
      }),
    );
    const result = service.toPublicDrone(
      (await service['drones'].findOne({
        where: { id: DRONE_ID },
      })) as Drone,
    );
    expect(result.maintenanceOverdue).toBe(true);
  });

  it('mover la fecha vuelve a habilitar el aviso de vencido', async () => {
    const { service, current } = build(
      drone({
        status: DroneStatus.MAINTENANCE,
        maintenanceUntil: '2026-11-04',
        maintenanceOverdueNotifiedAt: new Date('2026-11-05T05:00:00Z'),
      }),
    );
    await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.MAINTENANCE,
      estimatedEndDate: '2026-11-10',
    });
    expect(current().maintenanceOverdueNotifiedAt).toBeNull();
  });

  it('el historial sale del más reciente al más viejo, sin quién lo abrió', async () => {
    const { service } = build();
    await service.registerMaintenance(operator, DRONE_ID, {
      reason: 'Cambio de hélices',
      estimatedEndDate: '2026-11-08',
    });
    await service.updateStatus(operator, DRONE_ID, {
      status: DroneStatus.AVAILABLE,
    });
    const rows = await service.listMaintenance(operator, DRONE_ID);
    expect(rows).toEqual([
      {
        id: 'period-1',
        kind: DroneMaintenanceKind.MAINTENANCE,
        reason: 'Cambio de hélices',
        estimatedEndDate: '2026-11-08',
        flightsAtStart: 12,
        startedAt: NOW,
        closedAt: NOW,
      },
    ]);
  });

  it('el historial de un dron de otra central responde 403', async () => {
    const { service } = build(drone({ hubId: 'otra' }));
    await expect(service.listMaintenance(operator, DRONE_ID)).rejects.toThrow(
      'Esa central no está asignada a tu cuenta.',
    );
  });

  it('el historial de un dron que no existe responde 404', async () => {
    const { service } = build();
    service['drones'].findOne = jest.fn().mockResolvedValue(null);
    await expect(
      service.listMaintenance(operator, DRONE_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

describe('Reglas del preventivo', () => {
  afterEach(() => {
    delete process.env.DRONE_MAINTENANCE_CYCLES;
  });

  it('por defecto toca revisión cada 50 vuelos', () => {
    expect(maintenanceCycles()).toBe(DEFAULT_MAINTENANCE_CYCLES);
    expect(isMaintenanceDue(49)).toBe(false);
    expect(isMaintenanceDue(50)).toBe(true);
  });

  it('DRONE_MAINTENANCE_CYCLES lo cambia; un valor raro se ignora', () => {
    process.env.DRONE_MAINTENANCE_CYCLES = '2';
    expect(isMaintenanceDue(2)).toBe(true);
    process.env.DRONE_MAINTENANCE_CYCLES = 'muchos';
    expect(maintenanceCycles()).toBe(DEFAULT_MAINTENANCE_CYCLES);
  });

  it('vencido solo si sigue en mantenimiento y la fecha es de antes de hoy', () => {
    const today = '2026-11-05';
    const inShop = { status: DroneStatus.MAINTENANCE };
    expect(
      isMaintenanceOverdue(
        { ...inShop, maintenanceUntil: '2026-11-04' },
        today,
      ),
    ).toBe(true);
    expect(
      isMaintenanceOverdue({ ...inShop, maintenanceUntil: today }, today),
    ).toBe(false);
    expect(
      isMaintenanceOverdue({ ...inShop, maintenanceUntil: null }, today),
    ).toBe(false);
    expect(
      isMaintenanceOverdue(
        { status: DroneStatus.AVAILABLE, maintenanceUntil: '2026-11-04' },
        today,
      ),
    ).toBe(false);
  });
});

describe('MaintenanceSweepService', () => {
  function sweep(found: { overdue: Drone[]; due: Drone[] }) {
    const drones = {
      find: jest
        .fn()
        .mockResolvedValueOnce(found.overdue)
        .mockResolvedValueOnce(found.due),
      update: jest.fn().mockResolvedValue(undefined),
    };
    const inbox = {
      notifyHubOperators: jest.fn().mockResolvedValue(undefined),
    };
    const service = new MaintenanceSweepService(
      drones as never,
      inbox as unknown as InboxService,
    );
    return { service, drones, inbox };
  }

  it('avisa a los operadores de la central del mantenimiento vencido, una vez', async () => {
    const late = drone({
      status: DroneStatus.MAINTENANCE,
      maintenanceUntil: '2026-11-04',
    });
    const { service, drones, inbox } = sweep({ overdue: [late], due: [] });

    await service.runDue(NOW);

    expect(inbox.notifyHubOperators).toHaveBeenCalledWith(HUB, {
      kind: NotificationKind.MAINTENANCE_OVERDUE,
      title: 'Mantenimiento vencido',
      body: expect.stringContaining(
        'WG-198-001 debía terminar el 2026-11-04',
      ) as string,
    });
    expect(drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      { maintenanceOverdueNotifiedAt: NOW },
    );
  });

  it('avisa cuando un dron cumple los vuelos del preventivo', async () => {
    const worn = drone({ flightsSinceMaintenance: 50 });
    const { service, drones, inbox } = sweep({ overdue: [], due: [worn] });

    await service.runDue(NOW);

    expect(inbox.notifyHubOperators).toHaveBeenCalledWith(HUB, {
      kind: NotificationKind.MAINTENANCE_DUE,
      title: 'Le toca revisión a un dron',
      body: expect.stringContaining('lleva 50 vuelos') as string,
    });
    expect(drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      { maintenanceDueNotifiedAt: NOW },
    );
  });

  it('solo avisa: no cambia el estado de ningún dron', async () => {
    const late = drone({
      status: DroneStatus.MAINTENANCE,
      maintenanceUntil: '2026-11-04',
    });
    const { service, drones } = sweep({ overdue: [late], due: [] });
    await service.runDue(NOW);
    for (const [, changes] of drones.update.mock.calls as Array<
      [unknown, object]
    >) {
      expect(changes).not.toHaveProperty('status');
    }
  });

  it('si la base falla, lo registra y no revienta el intervalo', async () => {
    const { service, drones } = sweep({ overdue: [], due: [] });
    drones.find.mockReset().mockRejectedValue(new Error('base caída'));
    const error = jest
      .spyOn(service['logger'], 'error')
      .mockImplementation(() => undefined);
    await expect(service.runDue(NOW)).resolves.toBeUndefined();
    expect(error).toHaveBeenCalled();
  });
});
