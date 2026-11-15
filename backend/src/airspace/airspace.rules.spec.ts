import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { haversineKm, isInsideGeofence } from '../routing/routing.rules';
import {
  blockingPolygons,
  circlePolygon,
  coordinatedZones,
  destinationPoint,
  gatewayPlan,
  isBlocking,
  isPactedSite,
  joinGatewayLegs,
  zoneAt,
} from './airspace.rules';
import { SKVP_ARP, regionalAirspace } from './regional-airspace';
import { DELIVERY_POINTS, ESES, NODES } from './regional-network';

const zones = regionalAirspace();
const blocking = zones.filter(isBlocking);
const coordinated = coordinatedZones(zones);

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

  it('una zona dentro del anillo del aeropuerto no se rodea dos veces', () => {
    const polygons = blockingPolygons(zones);
    expect(polygons.length).toBeLessThan(blocking.length);
    // La subestación Valledupar (3,7 km del ARP + 2,3 km) cabe entera en el anillo.
    const substation = zones.find((zone) => zone.code === 'sub-valledupar');
    expect(polygons).not.toContain(substation?.polygon);
    // La cárcel (6,7 km + 2,3 km) toca el borde: se rodea igual.
    const prison = zones.find((zone) => zone.code === 'carcel-tramacua');
    expect(polygons).toContain(prison?.polygon);
    const aerodrome = zones.find(
      (zone) => zone.kind === AirspaceZoneKind.AERODROME,
    );
    expect(polygons).toContain(aerodrome?.polygon);
  });
});

describe('La red regional respeta las zonas (cobertura.md)', () => {
  it('cada nodo queda a más de 9 km del ARP y fuera de toda zona', () => {
    for (const node of Object.values(NODES)) {
      expect(haversineKm(node, SKVP_ARP)).toBeGreaterThan(9);
      expect(zoneAt(node, [...blocking, ...coordinated])).toBeNull();
    }
  });

  it('ninguna ESE ni punto de entrega queda en una zona bloqueante', () => {
    for (const site of [...Object.values(ESES), ...DELIVERY_POINTS]) {
      expect(zoneAt(site, blocking)).toBeNull();
    }
  });

  it('una ESE o un punto dentro de una zona coordinada es su sitio pactado', () => {
    for (const site of [...Object.values(ESES), ...DELIVERY_POINTS]) {
      const zone = zoneAt(site, coordinated);
      if (zone) {
        expect(zone.gateway).not.toBeNull();
        expect(isPactedSite(site, zone)).toBe(true);
      }
    }
  });

  it('las entradas pactadas quedan fuera de toda zona', () => {
    for (const zone of coordinated) {
      if (zone.gateway) {
        expect(zoneAt(zone.gateway, [...blocking, ...coordinated])).toBeNull();
      }
    }
  });

  it('las de precaución no bloquean', () => {
    const caution = zones.filter(
      (zone) => zone.kind === AirspaceZoneKind.CAUTION,
    );
    expect(caution.length).toBeGreaterThan(0);
    expect(caution.every((zone) => !isBlocking(zone))).toBe(true);
  });
});

describe('Entrada por la zona coordinada (RF-12)', () => {
  const atanquez = DELIVERY_POINTS.find(
    (point) => point.code === 'dp-atanquez',
  )!;

  it('a un sitio pactado se entra por la entrada de la zona', () => {
    const plan = gatewayPlan(NODES.north, atanquez, coordinated, {
      origin: true,
      destination: false,
    });
    expect(plan).not.toBeNull();
    expect(plan!.end).toEqual(
      zones.find((zone) => zone.code === 'resguardo-kankuamo')!.gateway,
    );
    expect(plan!.tail).toEqual([atanquez]);
  });

  it('a un punto cualquiera dentro de la zona no se llega', () => {
    const random = { latitude: 10.7, longitude: -73.37 };
    expect(
      gatewayPlan(NODES.north, random, coordinated, {
        origin: true,
        destination: false,
      }),
    ).toBeNull();
  });

  it('una central dentro de la zona sí se acepta como pactada', () => {
    const random = { latitude: 10.7, longitude: -73.37 };
    expect(
      gatewayPlan(NODES.north, random, coordinated, {
        origin: true,
        destination: true,
      }),
    ).not.toBeNull();
  });

  it('una zona sin entrada (Nabusímake) no tiene paso', () => {
    const nabusimake = { latitude: 10.5844, longitude: -73.5929 };
    expect(
      gatewayPlan(NODES.west, nabusimake, coordinated, {
        origin: true,
        destination: true,
      }),
    ).toBeNull();
  });

  it('el corredor completo suma los tramos pactados', () => {
    const plan = gatewayPlan(NODES.north, atanquez, coordinated, {
      origin: true,
      destination: false,
    })!;
    const core = {
      altitudeM: 100,
      distanceKm: haversineKm(NODES.north, plan.end),
      coordinates: [
        [NODES.north.longitude, NODES.north.latitude],
        [plan.end.longitude, plan.end.latitude],
      ] as Array<[number, number]>,
    };
    const joined = joinGatewayLegs(plan, core);
    expect(joined.coordinates.at(-1)).toEqual([
      atanquez.longitude,
      atanquez.latitude,
    ]);
    expect(joined.distanceKm).toBeCloseTo(
      haversineKm(NODES.north, plan.end) + haversineKm(plan.end, atanquez),
      1,
    );
  });
});
