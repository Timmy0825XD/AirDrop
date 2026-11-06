import { BadRequestException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { simClock } from '../common/clock/sim-clock';
import { CreateTemporaryGeofenceDto } from '../control/dto/create-temporary-geofence.dto';
import { geofenceDraft, polygonCenter } from '../control/timeline.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import {
  GeoJsonPolygon,
  activeGeofenceSql,
  isGeofenceActive,
  temporaryExpiry,
} from './geofences.rules';
import {
  GeofencesService,
  TEMPORARY_GEOFENCE_NOT_FOUND,
} from './geofences.service';

const NOW = new Date('2026-11-06T15:00:00.000Z');

/** Plaza Alfonso López: lejos de las centrales. */
const plaza: GeoJsonPolygon = {
  type: 'Polygon',
  coordinates: [
    [
      [-73.245, 10.476],
      [-73.24, 10.476],
      [-73.24, 10.48],
      [-73.245, 10.48],
      [-73.245, 10.476],
    ],
  ],
};

/** Cuadro sobre el Hospital Rosario Pumarejo. */
const overRosario: GeoJsonPolygon = {
  type: 'Polygon',
  coordinates: [
    [
      [-73.255, 10.462],
      [-73.252, 10.462],
      [-73.252, 10.465],
      [-73.255, 10.465],
      [-73.255, 10.462],
    ],
  ],
};

const rosario = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Hospital Rosario Pumarejo',
  latitude: 10.46314,
  longitude: -73.25322,
};

const FENCE_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

function fenceRow(expiresAt: Date | null) {
  return {
    id: FENCE_ID,
    name: 'Desfile aéreo',
    reason: 'Evento aéreo',
    polygon: JSON.stringify(plaza),
    createdByUserId: 'admin',
    createdAt: NOW,
    expiresAt,
  };
}

function build(deleted: ReturnType<typeof fenceRow>[] = []) {
  const geofences = {
    query: jest.fn((sql: string, params: unknown[]) => {
      if (sql.trim().startsWith('INSERT')) {
        return Promise.resolve([
          { ...fenceRow(params[5] as Date), createdAt: params[4] as Date },
        ]);
      }
      if (sql.trim().startsWith('DELETE')) {
        return Promise.resolve([deleted, deleted.length]);
      }
      return Promise.resolve([]);
    }),
  };
  const hubs = { find: jest.fn().mockResolvedValue([rosario]) };
  const flights = { recheckRoutes: jest.fn().mockResolvedValue(undefined) };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const service = new GeofencesService(
    geofences as never,
    hubs as never,
    flights as never,
    publisher as never,
  );
  return { service, geofences, flights, publisher };
}

const input = {
  name: 'Desfile aéreo',
  reason: 'Evento aéreo',
  polygon: plaza,
  durationMin: 30,
};

describe('Geovalla temporal: cuándo rige (RF-36)', () => {
  it('la del operador no vence; la temporal rige hasta su hora', () => {
    expect(isGeofenceActive({ expiresAt: null }, NOW)).toBe(true);
    expect(
      isGeofenceActive({ expiresAt: new Date(NOW.getTime() + 1) }, NOW),
    ).toBe(true);
    expect(isGeofenceActive({ expiresAt: NOW }, NOW)).toBe(false);
  });

  it('vence a la duración pedida desde la hora simulada', () => {
    expect(temporaryExpiry(NOW, 30).toISOString()).toBe(
      '2026-11-06T15:30:00.000Z',
    );
  });

  it('el filtro SQL deja pasar las del operador y las vigentes', () => {
    expect(activeGeofenceSql('$1')).toBe(
      '("expiresAt" IS NULL OR "expiresAt" > $1)',
    );
    expect(activeGeofenceSql('$3', 'g')).toBe(
      '(g."expiresAt" IS NULL OR g."expiresAt" > $3)',
    );
  });

  it('las rutas leen las geovallas con la hora simulada, no la real', async () => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
    try {
      simClock.change({ speed: 8 });
      jest.advanceTimersByTime(60_000);
      const manager = {
        query: jest
          .fn()
          .mockResolvedValue([{ polygon: JSON.stringify(plaza) }]),
      };
      const planner = new RoutePlannerService(
        {} as never,
        { stormPolygons: () => [] } as never,
      );
      await planner.loadGeofences(manager as never);
      const [sql, params] = manager.query.mock.calls[0] as [string, Date[]];
      expect(sql).toContain('"expiresAt" > $1');
      // A x8, un minuto real son 8 simulados.
      expect(params[0].toISOString()).toBe('2026-11-06T15:08:00.000Z');
    } finally {
      simClock.resetToRealTime();
      jest.useRealTimers();
    }
  });
});

describe('La consola lanza una geovalla temporal (RF-36, CU-38)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('se guarda con vencimiento, se anuncia y revisa los vuelos en el aire (RF-33)', async () => {
    const { service, geofences, flights, publisher } = build();
    const fence = await service.createTemporary('admin', input);
    const params = geofences.query.mock.calls[0][1];
    expect(params[4]).toEqual(NOW);
    expect(params[5]).toEqual(new Date('2026-11-06T15:30:00.000Z'));
    expect(fence.expiresAt).toBe('2026-11-06T15:30:00.000Z');
    expect(publisher.publish).toHaveBeenCalledWith({
      type: 'geofence',
      action: 'created',
      geofence: fence,
    });
    expect(flights.recheckRoutes).toHaveBeenCalledTimes(1);
  });

  it('no puede cubrir una central, como cualquier geovalla', async () => {
    const { service, geofences, publisher } = build();
    await expect(
      service.createTemporary('admin', { ...input, polygon: overRosario }),
    ).rejects.toThrow(BadRequestException);
    expect(geofences.query).not.toHaveBeenCalled();
    expect(publisher.publish).not.toHaveBeenCalled();
  });

  it('levantarla antes de tiempo la quita y lo cuenta', async () => {
    const row = fenceRow(new Date('2026-11-06T15:30:00.000Z'));
    const { service, publisher } = build([row]);
    const fence = await service.endTemporary(FENCE_ID);
    expect(fence.id).toBe(FENCE_ID);
    expect(publisher.publish).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'geofence', action: 'ended' }),
    );
  });

  it('una geovalla del operador o ya vencida no se levanta desde la consola', async () => {
    const { service, geofences } = build([]);
    await expect(service.endTemporary(FENCE_ID)).rejects.toThrow(
      new NotFoundException(TEMPORARY_GEOFENCE_NOT_FOUND),
    );
    const sql = String(geofences.query.mock.calls[0][0]);
    expect(sql).toContain('"expiresAt" IS NOT NULL');
  });

  it('al vencer desaparece sola y se cuenta una vez por geovalla', async () => {
    const row = fenceRow(NOW);
    const { service, publisher, geofences } = build([row]);
    await expect(service.sweepExpired()).resolves.toBe(1);
    expect(String(geofences.query.mock.calls[0][0])).toContain(
      '"expiresAt" <= $1',
    );
    expect(publisher.publish).toHaveBeenCalledTimes(1);
    expect(publisher.publish).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'geofence', action: 'ended' }),
    );
  });

  it('la duración va de 5 a 240 minutos', async () => {
    const check = async (durationMin: unknown) => {
      const failures = await validate(
        plainToInstance(CreateTemporaryGeofenceDto, {
          name: 'Zona',
          reason: 'Evento',
          polygon: plaza,
          durationMin,
        }),
      );
      return failures.flatMap((f) => Object.values(f.constraints ?? {}));
    };
    await expect(check(30)).resolves.toEqual([]);
    await expect(check(2)).resolves.toEqual([
      'La duración va de 5 a 240 minutos.',
    ]);
    await expect(check(500)).resolves.toEqual([
      'La duración va de 5 a 240 minutos.',
    ]);
  });
});

describe('La geovalla temporal en la línea de tiempo (RF-39)', () => {
  const fence = {
    name: 'Desfile aéreo',
    reason: 'Evento aéreo',
    polygon: plaza,
    createdAt: '2026-11-06T15:00:00.000Z',
    expiresAt: '2026-11-06T15:45:00.000Z',
  };

  it('el mapa se enfoca en el centro del polígono, sin repetir el cierre', () => {
    const center = polygonCenter(plaza);
    expect(center?.latitude).toBeCloseTo(10.478, 6);
    expect(center?.longitude).toBeCloseTo(-73.2425, 6);
  });

  it('al empezar dice cuánto dura y qué hace con las rutas', () => {
    const draft = geofenceDraft('created', fence);
    expect(draft).toMatchObject({
      kind: 'console',
      severity: 'warning',
      source: 'console',
      title: 'Geovalla temporal Desfile aéreo por 45 min',
    });
    expect(draft.detail).toContain('Evento aéreo.');
  });

  it('al terminar avisa en verde', () => {
    expect(geofenceDraft('ended', fence)).toMatchObject({
      severity: 'success',
      source: 'system',
      title: 'Terminó la geovalla temporal Desfile aéreo',
    });
  });
});
