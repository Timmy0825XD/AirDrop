import { Repository } from 'typeorm';
import { LEGAL_GEOFENCE_CLASSES } from '../common/enums/geofence-class.enum';
import { Geofence } from '../geofences/geofence.entity';
import { AirspaceService, seedLegalZonesIfEmpty } from './airspace.service';
import { regionalAirspace } from './regional-airspace';

const SQUARE = {
  type: 'Polygon',
  coordinates: [
    [
      [-73.25, 10.47],
      [-73.24, 10.47],
      [-73.24, 10.46],
      [-73.25, 10.46],
      [-73.25, 10.47],
    ],
  ],
};

type Call = [string, unknown[]];

function calls(query: jest.Mock): Call[] {
  return query.mock.calls as Call[];
}

function repo(query: jest.Mock) {
  return { query } as unknown as Repository<Geofence>;
}

describe('Zonas legales en la base (RF-43, RU-36)', () => {
  it('sin base usa las zonas de la semilla', () => {
    const airspace = new AirspaceService();
    expect(airspace.all()).toHaveLength(regionalAirspace().length);
  });

  it('la primera vez escribe la semilla, con el círculo de cada zona redonda', async () => {
    const query = jest.fn().mockResolvedValueOnce([{ count: 0 }]);
    query.mockResolvedValue([]);
    await seedLegalZonesIfEmpty(repo(query));
    const inserts = calls(query).slice(1);
    expect(inserts).toHaveLength(regionalAirspace().length);
    const skvp = inserts.find(([, params]) => params[2] === 'skvp');
    expect(skvp?.[1].slice(0, 2)).toEqual(['aerodrome', 'circle']);
    expect(skvp?.[1][8]).toBe(1500);
  });

  it('con zonas ya guardadas no duplica la semilla', async () => {
    const query = jest.fn().mockResolvedValueOnce([{ count: 3 }]);
    await seedLegalZonesIfEmpty(repo(query));
    expect(query).toHaveBeenCalledTimes(1);
    expect(calls(query)[0][1]).toEqual([LEGAL_GEOFENCE_CLASSES]);
  });

  it('carga solo las activas y conserva el círculo', async () => {
    const query = jest.fn().mockResolvedValue([
      {
        id: 'b9d1c8f4-0a0e-4d5e-9b66-1f2e3d4c5b6a',
        class: 'prohibited',
        shape: 'circle',
        code: 'cai-prueba',
        name: 'CAI de prueba',
        legalBasis: 'RAC 100.315(a)(13)',
        source: 'Equipo AirDrop',
        centerLatitude: '10.465000',
        centerLongitude: '-73.245000',
        radiusM: 100,
        polygon: JSON.stringify(SQUARE),
      },
    ]);
    const airspace = new AirspaceService(repo(query));
    await airspace.reload();
    expect(calls(query)[0][0]).toContain('active = true');
    expect(airspace.all()).toHaveLength(1);
    const [zone] = airspace.view();
    expect(zone.circle).toEqual({
      center: { latitude: 10.465, longitude: -73.245 },
      radiusM: 100,
    });
    expect(
      airspace.restrictionAt({ latitude: 10.465, longitude: -73.245 }),
    ).toMatchObject({ code: 'cai-prueba' });
  });
});
