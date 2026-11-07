import { ConflictException } from '@nestjs/common';
import { simClock } from '../common/clock/sim-clock';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { User } from '../users/user.entity';
import { DemoHubPlan, hubPlans } from './demo-scenario';
import {
  NO_DEMO_SCENARIO,
  droneResetState,
  resetDetail,
  stockRows,
} from './scenario-reset.rules';
import { ScenarioResetService } from './scenario-reset.service';

const NOW = new Date('2026-11-05T15:00:00.000Z');
const TODAY = '2026-11-05';
/** Una central de la semilla con drones en mantenimiento. */
const plan: DemoHubPlan = hubPlans.find((entry) => entry.droneNotes.length)!;
const noted = plan.droneNotes[0];
const admin = { id: 'admin-1' } as User;

describe('reinicio del escenario: reglas (RF-40)', () => {
  it('un dron sin nota en la semilla vuelve disponible', () => {
    const free = [1, 2, 3, 4, 5].find(
      (n) => !plan.droneNotes.some((note) => note.number === n),
    )!;
    expect(
      droneResetState(`${plan.dronePrefix}-0${free}`, plan, TODAY),
    ).toEqual({
      status: DroneStatus.AVAILABLE,
      maintenanceReason: null,
      maintenanceUntil: null,
    });
  });

  it('un dron con nota vuelve a mantenimiento con su motivo y su fecha desde hoy', () => {
    const state = droneResetState(
      `${plan.dronePrefix}-0${noted.number}`,
      plan,
      TODAY,
    );
    expect(state.status).toBe(DroneStatus.MAINTENANCE);
    expect(state.maintenanceReason).toBe(noted.reason);
    expect(state.maintenanceUntil! > TODAY).toBe(true);
  });

  it('el stock vuelve a las cantidades y lotes de la semilla', () => {
    const rows = stockRows(plan, 'hub-1', TODAY);
    expect(rows).toHaveLength(plan.stock.length);
    expect(rows[0]).toMatchObject({
      hubId: 'hub-1',
      name: plan.stock[0].name,
      quantity: plan.stock[0].quantity,
      lot: plan.stock[0].lot,
    });
    expect(rows.every((row) => row.expirationDate > TODAY)).toBe(true);
  });

  it('resume lo que hizo', () => {
    expect(
      resetDetail({
        orders: 4,
        drones: 15,
        inventoryItems: 18,
        geofences: 3,
        temporaryGeofences: 0,
      }),
    ).toBe(
      '4 pedidos borrados; 15 drones en su central; 18 lotes y 3 geovallas como en la semilla.',
    );
  });

  it('cuenta las geovallas temporales que quitó (RF-36)', () => {
    expect(
      resetDetail({
        orders: 0,
        drones: 15,
        inventoryItems: 18,
        geofences: 3,
        temporaryGeofences: 2,
      }),
    ).toBe(
      '0 pedidos borrados; 15 drones en su central; 18 lotes y 3 geovallas como en la semilla. 2 geovallas temporales quitadas.',
    );
  });
});

function build(hubs: Array<Partial<Hub>>) {
  const calls: string[] = [];
  const manager = {
    query: jest.fn((sql: string) => {
      calls.push(sql.trim().split(/\s+/).slice(0, 3).join(' '));
      return Promise.resolve([]);
    }),
    update: jest.fn().mockResolvedValue(undefined),
    delete: jest.fn().mockResolvedValue(undefined),
    save: jest.fn().mockResolvedValue(undefined),
    create: jest.fn((_entity: unknown, row: object) => row),
    find: jest.fn((entity: unknown) =>
      Promise.resolve(
        entity === Drone
          ? [
              {
                id: 'd1',
                hubId: 'hub-1',
                identifier: `${plan.dronePrefix}-01`,
              },
              {
                id: 'd2',
                hubId: 'hub-1',
                identifier: `${plan.dronePrefix}-0${noted.number}`,
              },
            ]
          : [],
      ),
    ),
    findOne: jest.fn().mockResolvedValue(null),
  };
  const dataSource = {
    getRepository: () => ({ find: jest.fn().mockResolvedValue(hubs) }),
    query: jest.fn().mockResolvedValue([
      { id: 'o1', planId: null },
      { id: 'o2', planId: 'p1' },
    ]),
    transaction: jest.fn((work: (m: typeof manager) => unknown) =>
      work(manager),
    ),
  };
  const order: string[] = [];
  const flights = {
    forget: jest.fn(() => {
      order.push('forget');
      return Promise.resolve();
    }),
  };
  const clock = {
    resetToRealTime: jest.fn(() => {
      order.push('clock');
      return Promise.resolve();
    }),
  };
  const timeline = {
    clear: jest.fn(() => {
      order.push('clear');
      return Promise.resolve();
    }),
    recordConsole: jest.fn(() => {
      order.push('record');
      return Promise.resolve();
    }),
  };
  const redis = { remove: jest.fn().mockResolvedValue(undefined) };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const weather = { clearAll: jest.fn().mockResolvedValue(undefined) };
  const geofences = { clearTemporary: jest.fn().mockResolvedValue(1) };
  const actors = {
    turnOff: jest.fn(() => {
      order.push('actors');
      return Promise.resolve();
    }),
  };
  const dispatcher = { forget: jest.fn() };
  const receiver = { forget: jest.fn() };
  const chaos = {
    turnOff: jest.fn(() => {
      order.push('chaos');
      return Promise.resolve();
    }),
  };
  const service = new ScenarioResetService(
    dataSource as never,
    flights as never,
    clock as never,
    timeline as never,
    redis as never,
    publisher as never,
    weather as never,
    geofences as never,
    actors as never,
    dispatcher as never,
    receiver as never,
    chaos as never,
  );
  return {
    service,
    actors,
    dispatcher,
    receiver,
    weather,
    geofences,
    manager,
    dataSource,
    flights,
    redis,
    publisher,
    timeline,
    order,
    calls,
  };
}

describe('ScenarioResetService (RF-40, CU-41)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('sin la semilla avisa que falta y no toca nada', async () => {
    const { service, flights, dataSource } = build([]);
    await expect(service.reset(admin)).rejects.toThrow(
      new ConflictException(NO_DEMO_SCENARIO),
    );
    expect(flights.forget).not.toHaveBeenCalled();
    expect(dataSource.transaction).not.toHaveBeenCalled();
  });

  it('borra todo pedido de las centrales de la demo, también los que esperan en su cola', async () => {
    const built = build([{ id: 'hub-1', name: plan.name }]);
    const summary = await built.service.reset(admin);

    const [sql, params] = built.dataSource.query.mock.calls[0] as [
      string,
      unknown[],
    ];
    expect(sql).toContain('"originHubId"');
    expect(sql).toContain('dispatchOffers');
    expect(params).toEqual([['hub-1'], ['hub-1']]);
    expect(built.flights.forget).toHaveBeenCalledWith(['o1', 'o2']);
    expect(built.calls).toEqual(
      expect.arrayContaining([
        'DELETE FROM delivery_codes',
        'DELETE FROM missions',
        'DELETE FROM notifications',
        'DELETE FROM orders',
        'DELETE FROM delivery_plans',
      ]),
    );
    expect(built.redis.remove).toHaveBeenCalledWith([
      'telemetry:order:o1',
      'telemetry:order:o2',
    ]);
    expect(summary.orders).toBe(2);
  });

  it('el reloj vuelve a la hora real antes de todo, y la línea de tiempo empieza de nuevo', async () => {
    const built = build([{ id: 'hub-1', name: plan.name }]);
    await built.service.reset(admin);
    // RF-37: los actores se apagan primero, para no crear pedidos a mitad.
    expect(built.order).toEqual([
      'actors',
      'chaos',
      'clock',
      'forget',
      'clear',
      'record',
    ]);
    expect(built.dispatcher.forget).toHaveBeenCalled();
    expect(built.receiver.forget).toHaveBeenCalled();
    // RF-40: sin clima, las tormentas ya no cuentan para las rutas.
    expect(built.weather.clearAll).toHaveBeenCalled();
    // RF-40: las geovallas temporales se van dentro de la misma transacción.
    expect(built.geofences.clearTemporary).toHaveBeenCalledWith(built.manager);
    expect(built.publisher.publish).toHaveBeenCalledWith({
      type: 'scenario-reset',
    });
    expect(built.timeline.recordConsole).toHaveBeenCalledWith(
      'Escenario reiniciado',
      expect.stringContaining('2 pedidos borrados'),
    );
  });

  it('deja la flota, el stock y las centrales como en la semilla', async () => {
    const built = build([{ id: 'hub-1', name: plan.name }]);
    await built.service.reset(admin);

    expect(built.manager.update).toHaveBeenCalledWith(
      Drone,
      { id: 'd1' },
      expect.objectContaining({
        status: DroneStatus.AVAILABLE,
        batteryPercent: 100,
      }),
    );
    expect(built.manager.update).toHaveBeenCalledWith(
      Drone,
      { id: 'd2' },
      expect.objectContaining({
        status: DroneStatus.MAINTENANCE,
        maintenanceReason: noted.reason,
      }),
    );
    expect(built.manager.delete).toHaveBeenCalledWith(
      InventoryItem,
      expect.anything(),
    );
    const calls = built.manager.save.mock.calls as Array<[unknown, unknown[]]>;
    const savedStock = calls.find(([entity]) => entity === InventoryItem)?.[1];
    expect(savedStock).toHaveLength(plan.stock.length);
    expect(built.manager.update).toHaveBeenCalledWith(Hub, expect.anything(), {
      status: HubStatus.ACTIVE,
      // RF-36: el reinicio también devuelve la energía.
      powerOutageUntil: null,
    });
  });
});
