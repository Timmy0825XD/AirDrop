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
import { DELIVERY_POINTS, ESES, NODES } from './regional-network';

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

  it('el helipunto, dentro del anillo del aeropuerto, no se rodea dos veces', () => {
    const polygons = blockingPolygons(zones);
    const helipad = zones.find((zone) => zone.code === 'skvp-helipad');
    expect(polygons).not.toContain(helipad?.polygon);
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
    expect(codes.filter((code) => code.startsWith('cai-'))).toHaveLength(11);
    expect(codes).toContain('pol-comando-cesar');
  });
});

describe('La red regional respeta las zonas (cobertura.md)', () => {
  it('ningún nodo, ESE ni punto queda dentro de una zona', () => {
    for (const site of [
      ...Object.values(NODES),
      ...Object.values(ESES),
      ...DELIVERY_POINTS,
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
      DELIVERY_POINTS.filter(
        (point) => point.nodeCode === NODES.valledupar.code,
      ),
    ).toHaveLength(4);
  });
});
