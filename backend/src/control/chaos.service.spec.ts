import { HubStatus } from '../common/enums/hub-status.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import { simClock } from '../common/clock/sim-clock';
import { ChaosService } from './chaos.service';

const NOW = new Date('2026-11-06T15:00:00.000Z');
const FLYING = {
  orderId: 'order-1',
  droneId: 'drone-old',
  coldLoad: false,
  midpoint: { latitude: 10.47, longitude: -73.25 },
};

function build(airborne = [FLYING]) {
  const redis = {
    read: jest.fn().mockResolvedValue(null),
    write: jest.fn().mockResolvedValue(undefined),
  };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const timeline = {
    recordConsole: jest.fn().mockResolvedValue(undefined),
    recordChaos: jest.fn().mockResolvedValue(undefined),
  };
  const events = {
    createWeather: jest.fn((_user: string, input: { radiusKm: number }) =>
      Promise.resolve({
        ...input,
        startsAt: NOW.toISOString(),
        endsAt: new Date(NOW.getTime() + 30 * 60_000).toISOString(),
      }),
    ),
    launchIncident: jest
      .fn()
      .mockResolvedValue({ latitude: 10.471, longitude: -73.251 }),
    createGeofence: jest.fn().mockResolvedValue({}),
    startOutage: jest.fn().mockResolvedValue({}),
  };
  const flights = { airborne: jest.fn(() => airborne) };
  const generator = {
    surge: jest.fn().mockResolvedValue({ created: [{}, {}, {}], failures: [] }),
  };
  const receiver = { markNoShow: jest.fn().mockResolvedValue('order-1') };
  const drones = {
    find: jest
      .fn()
      .mockResolvedValue([{ id: 'drone-old', flightsSinceMaintenance: 40 }]),
  };
  const hubs = {
    find: jest.fn().mockResolvedValue([
      {
        id: 'h1',
        name: 'Hospital',
        status: HubStatus.ACTIVE,
        latitude: 10.47,
        longitude: -73.24,
        powerOutageUntil: null,
      },
      {
        id: 'h2',
        name: 'Clínica',
        status: HubStatus.ACTIVE,
        latitude: 10.45,
        longitude: -73.26,
        powerOutageUntil: null,
      },
    ]),
  };
  const service = new ChaosService(
    { get: () => 'true' } as never,
    redis as never,
    publisher as never,
    timeline as never,
    events as never,
    flights as never,
    generator as never,
    receiver as never,
    drones as never,
    hubs as never,
  );
  return { service, events, timeline, publisher, generator, receiver };
}

/** Devuelve, en orden, los números dados; después repite el último. */
function sequence(...values: number[]): () => number {
  let index = 0;
  return () => values[Math.min(index++, values.length - 1)];
}

describe('ChaosService (RF-38, CU-40)', () => {
  afterEach(() => simClock.resetToRealTime());

  it('apagado no sortea nada', async () => {
    const { service, events } = build();
    await service.runDue(NOW);
    expect(events.createWeather).not.toHaveBeenCalled();
    expect(events.launchIncident).not.toHaveBeenCalled();
  });

  it('al encender lo cuenta y lo publica; el evento queda a nombre de quien lo encendió', async () => {
    const { service, timeline, publisher, events } = build();
    await service.change('admin-1', { enabled: true, intensity: 'low' });
    expect(timeline.recordConsole).toHaveBeenCalledWith(
      'Modo caos encendido, intensidad baja',
      null,
    );
    expect(publisher.publish).toHaveBeenCalledWith({
      type: 'chaos',
      chaos: { enabled: true, intensity: 'low' },
    });
    service.random = sequence(0); // clima, viento
    await service.fire('admin-1', NOW);
    expect(events.createWeather).toHaveBeenCalledWith(
      'admin-1',
      expect.objectContaining({ kind: WeatherKind.WIND }),
    );
  });

  it('una falla de dron cae sobre el más gastado y sale marcada como caos', async () => {
    const { service, events, timeline } = build();
    await service.change('admin-1', { enabled: true });
    // 0,5 → dron (40–75); 0 → batería degradada, la primera de la lista.
    service.random = sequence(0.5, 0, 0);
    await service.fire('admin-1', NOW);
    expect(events.launchIncident).toHaveBeenCalledWith(
      'drone-old',
      IncidentKind.BATTERY_DEGRADED,
    );
    expect(timeline.recordChaos).toHaveBeenCalledWith(
      'Caos: batería degradada',
      null,
      expect.objectContaining({ droneId: 'drone-old', orderId: 'order-1' }),
    );
  });

  it('sin drones en el aire, el clima cae en un barrio de la demo', async () => {
    const { service, events } = build([]);
    await service.change('admin-1', { enabled: true });
    service.random = sequence(0.1);
    await service.fire('admin-1', NOW);
    expect(events.launchIncident).not.toHaveBeenCalled();
    expect(events.createWeather).toHaveBeenCalled();
  });

  it('si el dominio rechaza el evento, no lo cuenta y sigue', async () => {
    const { service, events, timeline } = build();
    await service.change('admin-1', { enabled: true });
    events.launchIncident.mockRejectedValue(new Error('El dron ya aterriza.'));
    service.random = sequence(0.5, 0, 0);
    await expect(service.fire('admin-1', NOW)).resolves.toBeNull();
    expect(timeline.recordChaos).not.toHaveBeenCalled();
  });

  it('espera su turno: no sortea antes de la hora del siguiente evento', async () => {
    const { service, events } = build();
    simClock.restore({
      anchorSimMs: NOW.getTime(),
      anchorRealMs: Date.now(),
      speed: 1,
      paused: true,
    } as never);
    service.random = () => 0; // en alta, el primero a 2 min
    await service.change('admin-1', { enabled: true, intensity: 'high' });
    await service.runDue(new Date(NOW.getTime() + 60_000));
    expect(events.createWeather).not.toHaveBeenCalled();
    await service.runDue(new Date(NOW.getTime() + 120_000));
    expect(events.createWeather).toHaveBeenCalledTimes(1);
  });

  it('el reinicio lo apaga sin contarlo en la línea nueva', async () => {
    const { service, timeline } = build();
    await service.change('admin-1', { enabled: true });
    timeline.recordConsole.mockClear();
    await service.turnOff();
    expect(service.view()).toEqual({ enabled: false, intensity: 'medium' });
    expect(timeline.recordConsole).not.toHaveBeenCalled();
  });
});
