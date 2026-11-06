import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { User } from '../users/user.entity';
import { CreateGeofenceDto } from './dto/create-geofence.dto';
import { UpdateGeofenceDto } from './dto/update-geofence.dto';
import { GeoJsonPolygon, assertCoversNoHub } from './geofences.rules';
import { GeofencesService } from './geofences.service';

/** Cuadro de ~330 m alrededor del Hospital Rosario Pumarejo. */
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

/** Plaza Alfonso López: no cubre ninguna de las dos centrales. */
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

const rosario = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Hospital Rosario Pumarejo',
  latitude: 10.46314,
  longitude: -73.25322,
};
const clinica = {
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  name: 'Clínica Laura Daniela',
  latitude: 10.4742,
  longitude: -73.2598,
};

const COVERS_ROSARIO =
  'La geovalla no puede cubrir una central: Hospital Rosario Pumarejo queda dentro.';

const operator = { id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee' } as User;

const row = (polygon: GeoJsonPolygon) => ({
  id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  name: 'Zona',
  reason: 'Evento',
  polygon: JSON.stringify(polygon),
  createdByUserId: operator.id,
  createdAt: new Date('2026-11-05T15:00:00.000Z'),
  expiresAt: null,
});

function build() {
  const geofences = {
    query: jest.fn((sql: string, params: unknown[]) => {
      const polygon = JSON.parse(
        String(sql.startsWith('INSERT') ? params[2] : params[3]),
      ) as GeoJsonPolygon;
      const saved = [row(polygon)];
      return Promise.resolve(sql.startsWith('UPDATE') ? [saved, 1] : saved);
    }),
    findOne: jest.fn().mockResolvedValue({ id: row(plaza).id }),
  };
  const hubs = { find: jest.fn().mockResolvedValue([rosario, clinica]) };
  const flights = { recheckRoutes: jest.fn().mockResolvedValue(undefined) };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const service = new GeofencesService(
    geofences as never,
    hubs as never,
    flights as never,
    publisher as never,
  );
  return { service, geofences, flights };
}

async function errors<T extends object>(
  dto: new () => T,
  data: object,
): Promise<string[]> {
  const failures = await validate(plainToInstance(dto, data));
  return failures.flatMap((failure) =>
    Object.values(failure.constraints ?? {}),
  );
}

describe('Una geovalla cambia la ruta de los drones en el aire (RF-33)', () => {
  const operatorUser = { id: 'op-1' } as never;

  it('crear una geovalla revisa los vuelos en curso', async () => {
    const { service, flights } = build();
    await service.create(operatorUser, {
      name: 'Evento',
      reason: 'Concierto',
      polygon: plaza,
    } as never);
    expect(flights.recheckRoutes).toHaveBeenCalledTimes(1);
  });

  it('editar solo el nombre no revisa nada; mover el polígono sí', async () => {
    const { service, flights } = build();
    await service.update(row(plaza).id, { name: 'Otro nombre' } as never);
    expect(flights.recheckRoutes).not.toHaveBeenCalled();
    await service.update(row(plaza).id, { polygon: plaza } as never);
    expect(flights.recheckRoutes).toHaveBeenCalledTimes(1);
  });

  it('si revisar los vuelos falla, la geovalla queda guardada igual', async () => {
    const { service, flights } = build();
    flights.recheckRoutes.mockRejectedValue(new Error('Redis caído'));
    await expect(
      service.create(operatorUser, {
        name: 'Evento',
        reason: 'Concierto',
        polygon: plaza,
      } as never),
    ).resolves.toMatchObject({ name: expect.any(String) });
  });
});

describe('Una geovalla no cubre una central', () => {
  it('la regla nombra la central que queda dentro', () => {
    expect(() => assertCoversNoHub(overRosario, [rosario, clinica])).toThrow(
      COVERS_ROSARIO,
    );
  });

  it('la regla deja pasar un polígono lejos de las centrales', () => {
    expect(() => assertCoversNoHub(plaza, [rosario, clinica])).not.toThrow();
  });

  it('una central cerca del borde, pero afuera, no bloquea', () => {
    // A ~110 m del borde: el router ya acepta extremos dentro del margen.
    const near = { ...rosario, longitude: -73.251 };
    expect(() => assertCoversNoHub(overRosario, [near])).not.toThrow();
  });

  it('crear sobre una central responde 400 y no guarda', async () => {
    const { service, geofences } = build();
    const attempt = service.create(operator, {
      name: 'Sobre el hospital',
      reason: 'Evento',
      polygon: overRosario,
    });
    await expect(attempt).rejects.toBeInstanceOf(BadRequestException);
    await expect(attempt).rejects.toThrow(COVERS_ROSARIO);
    expect(geofences.query).not.toHaveBeenCalled();
  });

  it('crear lejos de las centrales sí guarda', async () => {
    const { service, geofences } = build();
    await service.create(operator, {
      name: 'Plaza Alfonso López',
      reason: 'Evento',
      polygon: plaza,
    });
    expect(geofences.query).toHaveBeenCalledTimes(1);
  });

  it('mover una geovalla encima de una central responde 400 y no guarda', async () => {
    const { service, geofences } = build();
    const attempt = service.update(row(plaza).id, { polygon: overRosario });
    await expect(attempt).rejects.toThrow(COVERS_ROSARIO);
    expect(geofences.query).not.toHaveBeenCalled();
  });

  it('cambiar solo el nombre no revisa las centrales', async () => {
    const { service, geofences } = build();
    await service.update(row(plaza).id, { name: 'Plaza' });
    expect(geofences.query).toHaveBeenCalledTimes(1);
  });
});

describe('Nombre y motivo de la geovalla', () => {
  const body = { name: 'Zona', reason: 'Evento', polygon: plaza };

  it.each([
    ['name', '', 'El nombre es obligatorio.'],
    ['name', '   ', 'El nombre es obligatorio.'],
    ['reason', '', 'El motivo es obligatorio.'],
    ['reason', '   ', 'El motivo es obligatorio.'],
  ])('al crear, %s = %j se rechaza', async (field, value, message) => {
    expect(
      await errors(CreateGeofenceDto, { ...body, [field]: value }),
    ).toContain(message);
  });

  it.each([
    ['name', 'El nombre no puede quedar vacío.'],
    ['reason', 'El motivo no puede quedar vacío.'],
  ])('al editar, %s en blanco se rechaza', async (field, message) => {
    expect(await errors(UpdateGeofenceDto, { [field]: '  ' })).toContain(
      message,
    );
  });

  it('al editar, omitir el nombre y el motivo sigue valiendo', async () => {
    expect(await errors(UpdateGeofenceDto, { polygon: plaza })).toEqual([]);
  });
});
