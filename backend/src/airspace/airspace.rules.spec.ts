import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { haversineKm, isInsideGeofence } from '../routing/routing.rules';
import {
  blockingPolygons,
  circlePolygon,
  destinationPoint,
  isBlocking,
  zoneAt,
} from './airspace.rules';
import {
  AERODROME_RADIUS_KM,
  SKVP_ARP,
  regionalAirspace,
} from './regional-airspace';
import { DEMO_PLACES, ESES, NODES } from './regional-network';

const zones = regionalAirspace();

describe('Geometría de las zonas (RF-43)', () => {
  it('el círculo contiene todo su radio y nada mucho más allá', () => {
    const polygon = circlePolygon(SKVP_ARP, 9, 32);
    for (const bearing of [0, 37, 90, 181, 270, 333]) {
      expect(
        isInsideGeofence(destinationPoint(SKVP_ARP, bearing, 8.95), [polygon]),
      ).toBe(true);
      expect(
        isInsideGeofence(destinationPoint(SKVP_ARP, bearing, 9.3), [polygon]),
      ).toBe(false);
    }
  });

  it('destinationPoint y haversine coinciden', () => {
    const far = destinationPoint(SKVP_ARP, 45, 12);
    expect(haversineKm(SKVP_ARP, far)).toBeCloseTo(12, 2);
  });

  it('una zona entera dentro del anillo del aeropuerto no se rodea dos veces', () => {
    const inside = {
      code: 'dentro',
      kind: AirspaceZoneKind.HELIPORT,
      name: 'Helipunto',
      legalBasis: '',
      source: '',
      polygon: circlePolygon(
        { latitude: 10.43261, longitude: -73.24885 },
        0.3,
        16,
      ),
    };
    const polygons = blockingPolygons([...zones, inside]);
    expect(polygons).not.toContain(inside.polygon);
    const aerodrome = zones.find(
      (zone) => zone.kind === AirspaceZoneKind.AERODROME,
    );
    expect(polygons).toContain(aerodrome?.polygon);
  });
});

describe('Escala de la demo (espacio-aereo.md)', () => {
  it('todas las zonas bloquean', () => {
    expect(zones.every(isBlocking)).toBe(true);
  });

  it('el aeropuerto tiene 1,5 km: el centro de Valledupar queda libre', () => {
    expect(AERODROME_RADIUS_KM).toBe(1.5);
    const plazaAlfonsoLopez = { latitude: 10.4775, longitude: -73.2436 };
    expect(zoneAt(plazaAlfonsoLopez, zones)).toBeNull();
    expect(zoneAt(destinationPoint(SKVP_ARP, 0, 1.4), zones)?.kind).toBe(
      AirspaceZoneKind.AERODROME,
    );
  });

  it('un CAI ocupa unos 100 m: a 150 m ya no hay zona', () => {
    const cai = { latitude: 10.4705, longitude: -73.2494 };
    expect(zoneAt(cai, zones)?.code).toBe('cai-gobernacion');
    expect(zoneAt(destinationPoint(cai, 90, 0.15), zones)).toBeNull();
  });

  it('Valledupar tiene sus CAI y el comando de policía', () => {
    const codes = zones.map((zone) => zone.code);
    expect(codes.filter((code) => code.startsWith('cai-'))).toHaveLength(8);
  });

  it('no hay dos zonas a menos de 300 m ni un CAI dentro del aeropuerto', () => {
    const centers = zones.map((zone) => {
      const ring = zone.polygon.coordinates[0].slice(0, -1);
      return {
        code: zone.code,
        latitude: ring.reduce((sum, [, lat]) => sum + lat, 0) / ring.length,
        longitude: ring.reduce((sum, [lng]) => sum + lng, 0) / ring.length,
      };
    });
    for (const [index, zone] of centers.entries()) {
      for (const other of centers.slice(index + 1)) {
        expect({
          pair: `${zone.code}/${other.code}`,
          near: haversineKm(zone, other) < 0.3,
        }).toEqual({
          pair: `${zone.code}/${other.code}`,
          near: false,
        });
      }
      if (zone.code.startsWith('cai-')) {
        expect(haversineKm(zone, SKVP_ARP)).toBeGreaterThan(
          AERODROME_RADIUS_KM,
        );
      }
    }
  });
});

describe('La red regional respeta las zonas (cobertura.md)', () => {
  it('ningún nodo, ESE ni punto queda dentro de una zona', () => {
    for (const site of [
      ...Object.values(NODES),
      ...Object.values(ESES),
      ...DEMO_PLACES,
    ]) {
      expect({
        site: site.code,
        zone: zoneAt(site, zones)?.code ?? null,
      }).toEqual({
        site: site.code,
        zone: null,
      });
    }
  });

  it('Valledupar tiene nodo, dos ESE y cuatro puntos', () => {
    expect(NODES.valledupar.municipality).toBe('Valledupar');
    expect(
      Object.values(ESES).filter((ese) => ese.municipality === 'Valledupar'),
    ).toHaveLength(2);
    expect(
      DEMO_PLACES.filter(
        (point) => point.nodeCode === NODES.valledupar.code,
      ),
    ).toHaveLength(4);
  });
});
