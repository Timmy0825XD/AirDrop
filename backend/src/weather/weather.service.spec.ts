import { BadRequestException } from '@nestjs/common';
import { simClock } from '../common/clock/sim-clock';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import { ConsoleEventsService } from '../control/console-events.service';
import { pendingAlertKinds } from '../control/pending-alerts.rules';
import { weatherDraft } from '../control/timeline.rules';
import { OrderStatus } from '../common/enums/order-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { chooseDrone } from '../decision/decision.rules';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { RoutePlannerService } from '../routing/route-planner.service';
import {
  GUST_BELOW_SPEED,
  WIND_NEEDS_SPEED,
  WeatherService,
} from './weather.service';
import { WEATHER_STORM_BLOCKS } from './weather.rules';

const NOW = new Date('2026-11-05T15:00:00.000Z');

function build() {
  const rows: object[] = [];
  const repo = {
    find: jest.fn().mockResolvedValue([]),
    create: jest.fn((row: object) => row),
    save: jest.fn((row: object) => {
      const saved = { id: `cell-${rows.length + 1}`, ...row };
      rows.push(saved);
      return Promise.resolve(saved);
    }),
    update: jest.fn().mockResolvedValue(undefined),
    clear: jest.fn().mockResolvedValue(undefined),
  };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const service = new WeatherService(repo as never, publisher as never);
  return { service, repo, publisher };
}

const storm = {
  kind: WeatherKind.STORM,
  latitude: 10.46,
  longitude: -73.25,
  radiusKm: 2,
  durationMin: 30,
};

describe('WeatherService (RF-32)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('una tormenta rige por su duración en hora simulada y se publica', async () => {
    const { service, publisher } = build();
    const cell = await service.create('admin', storm);
    expect(cell.endsAt.getTime() - cell.startsAt.getTime()).toBe(30 * 60_000);
    expect(service.active()).toHaveLength(1);
    expect(service.stormPolygons()).toHaveLength(1);
    expect(publisher.publish).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'weather', action: 'created' }),
    );
    // A x8, 30 minutos simulados pasan en 3 min 45 s reales.
    simClock.change({ speed: 8 });
    jest.advanceTimersByTime(226_000);
    expect(service.active()).toEqual([]);
  });

  it('el viento pide velocidad y dirección, y ráfagas no menores que el sostenido', async () => {
    const { service } = build();
    const wind = { ...storm, kind: WeatherKind.WIND };
    await expect(service.create('admin', wind)).rejects.toThrow(
      new BadRequestException(WIND_NEEDS_SPEED),
    );
    await expect(
      service.create('admin', {
        ...wind,
        windSpeedMs: 12,
        windGustMs: 8,
        windFromDeg: 90,
      }),
    ).rejects.toThrow(new BadRequestException(GUST_BELOW_SPEED));
  });

  it('cortar una celda la saca de inmediato y avisa una sola vez', async () => {
    const { service, publisher } = build();
    const cell = await service.create('admin', storm);
    await service.end(cell.id);
    await service.end(cell.id);
    expect(service.active()).toEqual([]);
    const ended = publisher.publish.mock.calls.filter(
      ([event]) => (event as { action?: string }).action === 'ended',
    );
    expect(ended).toHaveLength(1);
  });

  it('el reinicio borra todo el clima (RF-40)', async () => {
    const { service, repo } = build();
    await service.create('admin', storm);
    await service.clearAll();
    expect(repo.clear).toHaveBeenCalled();
    expect(service.active()).toEqual([]);
  });
});

describe('el clima en el resto del sistema', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('la tormenta de la consola hace revisar las rutas en el aire; la lluvia no', async () => {
    const { service } = build();
    const flights = { recheckRoutes: jest.fn().mockResolvedValue(undefined) };
    const events = new ConsoleEventsService(
      service,
      flights as never,
      {} as never,
      {} as never,
    );
    await events.createWeather('admin', {
      ...storm,
      kind: WeatherKind.RAIN,
    });
    expect(flights.recheckRoutes).not.toHaveBeenCalled();
    await events.createWeather('admin', storm);
    expect(flights.recheckRoutes).toHaveBeenCalledTimes(1);
  });

  it('las rutas no cruzan una tormenta, pero un punto de entrega bajo ella sigue valiendo', async () => {
    const { service } = build();
    await service.create('admin', storm);
    const routes = new RoutePlannerService(
      { manager: { query: jest.fn().mockResolvedValue([]) } } as never,
      service,
    );
    const manager = { query: jest.fn().mockResolvedValue([]) };
    expect(await routes.loadPolygons(manager as never)).toHaveLength(1);
    await expect(
      routes.assertDestinationAllowed(
        { longitude: -73.25, latitude: 10.46 },
        manager as never,
      ),
    ).resolves.toBeUndefined();
  });

  it('el motor descarta los drones con el motivo del clima', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      weatherFlyable: false,
      weatherReason: WEATHER_STORM_BLOCKS,
      candidates: [
        {
          drone: {
            id: 'd1',
            identifier: 'WC-01',
            status: DroneStatus.AVAILABLE,
            maxPayloadKg: 6,
            maxRangeKm: 110,
            held: null,
            batteryPercent: 100,
            lastFlightEndedAt: null,
          },
          distanceKm: 5,
        },
      ],
    });
    expect(result.chosen).toBeNull();
    expect(result.discarded[0].reason).toBe(WEATHER_STORM_BLOCKS);
  });

  it('la alerta de viento queda en la bandeja mientras el dron no vuelva', () => {
    expect(
      pendingAlertKinds(
        {
          batteryAlert: false,
          failureAlert: false,
          windAlert: true,
          returnedAt: null,
        },
        { status: OrderStatus.IN_FLIGHT, coldChainAlertAt: null },
      ),
    ).toEqual(['wind_limit']);
  });

  it('la línea de tiempo cuenta el clima en palabras', () => {
    const base = {
      latitude: 10.46,
      longitude: -73.25,
      radiusKm: 2,
      windSpeedMs: null,
      windFromDeg: null,
      startsAt: NOW.toISOString(),
      endsAt: new Date(NOW.getTime() + 30 * 60_000).toISOString(),
    };
    expect(
      weatherDraft('created', { ...base, kind: WeatherKind.STORM }).title,
    ).toBe('Tormenta en 2 km por 30 min');
    expect(
      weatherDraft('created', {
        ...base,
        kind: WeatherKind.WIND,
        windSpeedMs: 12,
        windFromDeg: 45,
      }).title,
    ).toBe('Viento de 12 m/s del noreste en 2 km por 30 min');
    expect(
      weatherDraft('ended', { ...base, kind: WeatherKind.STORM }).title,
    ).toBe('Pasó la tormenta');
  });
});
