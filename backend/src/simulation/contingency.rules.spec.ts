import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { haversineKm, isInsideGeofence } from '../routing/routing.rules';
import {
  ContingencyInput,
  LANDING_CLEARANCE_KM,
  applyEffect,
  chooseProtocol,
  emergencyCorridor,
  homeCorridor,
  incidentSeverity,
  percentToFinish,
  percentToLand,
  rescueDurationMs,
  safeLandingPoint,
} from './contingency.rules';
import { FlightPhase } from './simulation.rules';

const outbound = (
  overrides: Partial<ContingencyInput> = {},
): ContingencyInput => ({
  kind: IncidentKind.BATTERY_SHORT,
  leg: RouteLeg.OUTBOUND,
  phase: FlightPhase.CRUISE,
  batteryPercent: 60,
  finishPercent: 30,
  homePercent: 10,
  ...overrides,
});

/** Cuadro de ~1,1 km de lado alrededor de (10.46, -73.25). */
const storm: GeoJsonPolygon = {
  type: 'Polygon',
  coordinates: [
    [
      [-73.255, 10.455],
      [-73.245, 10.455],
      [-73.245, 10.465],
      [-73.255, 10.465],
      [-73.255, 10.455],
    ],
  ],
};

describe('Protocolo según alcance (RF-34)', () => {
  it('si termina la misión con la reserva del 20 %, sigue', () => {
    expect(chooseProtocol(outbound({ batteryPercent: 50 }))).toBe(
      ContingencyProtocol.CONTINUE,
    );
  });

  it('si no termina pero vuelve a la central con la reserva, vuelve', () => {
    expect(chooseProtocol(outbound({ batteryPercent: 40 }))).toBe(
      ContingencyProtocol.RETURN_TO_HUB,
    );
  });

  it('si tampoco vuelve, aterriza de emergencia', () => {
    expect(chooseProtocol(outbound({ batteryPercent: 25 }))).toBe(
      ContingencyProtocol.EMERGENCY_LANDING,
    );
  });

  it('con viento sobre el límite no sigue aunque le alcance: vuelve', () => {
    expect(
      chooseProtocol(
        outbound({ kind: IncidentKind.WIND_LIMIT, batteryPercent: 90 }),
      ),
    ).toBe(ContingencyProtocol.RETURN_TO_HUB);
  });

  it('sin camino seguro a destino ni a la central, aterriza', () => {
    expect(
      chooseProtocol(
        outbound({
          kind: IncidentKind.ROUTE_BLOCKED,
          batteryPercent: 90,
          finishPercent: null,
          homePercent: null,
        }),
      ),
    ).toBe(ContingencyProtocol.EMERGENCY_LANDING);
  });

  it('de regreso, seguir es llegar a la central', () => {
    const back = outbound({
      leg: RouteLeg.RETURN,
      kind: IncidentKind.WIND_LIMIT,
      finishPercent: null,
      homePercent: 10,
    });
    expect(chooseProtocol({ ...back, batteryPercent: 35 })).toBe(
      ContingencyProtocol.CONTINUE,
    );
    expect(chooseProtocol({ ...back, batteryPercent: 25 })).toBe(
      ContingencyProtocol.EMERGENCY_LANDING,
    );
  });

  it('bajando ya, termina de bajar', () => {
    expect(
      chooseProtocol(
        outbound({ phase: FlightPhase.DESCENT, batteryPercent: 1 }),
      ),
    ).toBe(ContingencyProtocol.CONTINUE);
  });
});

describe('Batería crítica: basta el margen de aterrizaje (decisión del 2026-11-06)', () => {
  const critical = (overrides: Partial<ContingencyInput>) =>
    outbound({ kind: IncidentKind.BATTERY_CRITICAL, ...overrides });

  it('a 500 m de la central, de regreso, sigue con un 5 % al aterrizar', () => {
    const homePercent = percentToLand(0.5, 110);
    expect(
      chooseProtocol(
        critical({ leg: RouteLeg.RETURN, batteryPercent: 19.9, homePercent }),
      ),
    ).toBe(ContingencyProtocol.CONTINUE);
  });

  it('de ida, si llega al destino y vuelve con el 5 %, sigue', () => {
    expect(
      chooseProtocol(critical({ batteryPercent: 19, finishPercent: 13 })),
    ).toBe(ContingencyProtocol.CONTINUE);
  });

  it('si no le alcanza para entregar, vuelve si llega a la central con el 5 %', () => {
    expect(
      chooseProtocol(
        critical({ batteryPercent: 19, finishPercent: 30, homePercent: 9 }),
      ),
    ).toBe(ContingencyProtocol.RETURN_TO_HUB);
  });

  it('sin margen para nada, aterriza de emergencia', () => {
    expect(
      chooseProtocol(
        critical({ batteryPercent: 12, finishPercent: 30, homePercent: 9 }),
      ),
    ).toBe(ContingencyProtocol.EMERGENCY_LANDING);
  });

  it('los demás incidentes piden la reserva del 20 %', () => {
    expect(
      chooseProtocol(outbound({ batteryPercent: 19, homePercent: 9 })),
    ).toBe(ContingencyProtocol.EMERGENCY_LANDING);
  });
});

describe('Cuentas de batería del protocolo', () => {
  it('aterrizar desde el aire: crucero, descenso y aterrizaje', () => {
    // 11 km de 110 km son el 10 %, más 1 % de descenso y 3 % de aterrizaje.
    expect(percentToLand(11, 110)).toBeCloseTo(14, 6);
  });

  it('de ida suma el regreso entero por el mismo corredor', () => {
    // 14 % para llegar y 8 % + 10 % del tramo de regreso.
    expect(
      percentToFinish({ remainingKm: 11, returnKm: 11, maxRangeKm: 110 }),
    ).toBeCloseTo(32, 6);
  });

  it('la gravedad: la batería que no alcanza un desvío es leve', () => {
    expect(incidentSeverity(IncidentKind.BATTERY_SHORT)).toBe('minor');
    expect(incidentSeverity(IncidentKind.WIND_LIMIT)).toBe('major');
  });
});

describe('Aterrizaje de emergencia y rescate (RF-34)', () => {
  it('fuera de toda zona baja donde va', () => {
    const here = { latitude: 10.5, longitude: -73.3 };
    expect(safeLandingPoint(here, [storm])).toEqual(here);
  });

  it('dentro de una tormenta sale por el borde más cercano', () => {
    // A 300 m del borde norte y a 500 m de los demás.
    const here = { latitude: 10.462, longitude: -73.25 };
    const landing = safeLandingPoint(here, [storm]);
    expect(isInsideGeofence(landing, [storm])).toBe(false);
    expect(landing.latitude).toBeGreaterThan(10.465);
    expect(haversineKm(here, landing)).toBeCloseTo(
      0.332 + LANDING_CLEARANCE_KM,
      1,
    );
  });

  it('el rescate sale por tierra a 30 km/h y tarda 10 min en recoger: 6 km son 22 min', () => {
    const hub = { latitude: 10.46, longitude: -73.25 };
    // 6 km al norte (0,05426° de latitud).
    const landing = { latitude: 10.46 + 6 / 110.574, longitude: -73.25 };
    expect(rescueDurationMs(hub, landing) / 60_000).toBeCloseTo(22, 0);
  });

  it('el corredor de emergencia sigue lo volado y termina donde baja', () => {
    const corridor = {
      altitudeM: 100,
      distanceKm: 10.94,
      coordinates: [
        [-73.3, 10.46],
        [-73.2, 10.46],
      ] as Array<[number, number]>,
    };
    const landing = { latitude: 10.47, longitude: -73.25 };
    const hop = emergencyCorridor(corridor, 5, landing);
    expect(hop.coordinates[0]).toEqual([-73.3, 10.46]);
    expect(hop.coordinates.at(-1)).toEqual([-73.25, 10.47]);
    expect(hop.distanceKm).toBeGreaterThan(5);
    expect(hop.distanceKm).toBeLessThan(6.5);
  });

  it('el camino a la central rodea las zonas; si el dron quedó dentro, sale', () => {
    const inside = { latitude: 10.46, longitude: -73.25 };
    const hub = { latitude: 10.46, longitude: -73.2 };
    expect(homeCorridor(inside, hub, [storm])).not.toBeNull();
    const outside = { latitude: 10.46, longitude: -73.3 };
    const around = homeCorridor(outside, hub, [storm]);
    expect(around?.coordinates.length).toBeGreaterThan(2);
  });
});

describe('Catálogo de la consola: protocolos fijos y efectos (RF-34)', () => {
  it('perderlo o un choque grave no dejan elegir, ni siquiera bajando', () => {
    expect(
      chooseProtocol(
        outbound({ kind: IncidentKind.DRONE_LOST, phase: FlightPhase.DESCENT }),
      ),
    ).toBe(ContingencyProtocol.LOST);
    expect(
      chooseProtocol(outbound({ kind: IncidentKind.COLLISION_MAJOR })),
    ).toBe(ContingencyProtocol.CRASH);
  });

  it('dos motores o GPS sin respaldo bajan aunque la batería alcance', () => {
    for (const kind of [
      IncidentKind.DUAL_MOTOR_FAILURE,
      IncidentKind.GPS_LOSS_MAJOR,
    ]) {
      expect(chooseProtocol(outbound({ kind, batteryPercent: 99 }))).toBe(
        ContingencyProtocol.EMERGENCY_LANDING,
      );
    }
  });

  it('GPS leve y falla del frío siguen con alerta aunque la batería esté justa', () => {
    for (const kind of [
      IncidentKind.GPS_LOSS_MINOR,
      IncidentKind.COOLING_FAILURE,
    ]) {
      expect(chooseProtocol(outbound({ kind, batteryPercent: 21 }))).toBe(
        ContingencyProtocol.CONTINUE,
      );
    }
  });

  it('sin enlace vuelve a la central aunque le alcance para entregar', () => {
    expect(
      chooseProtocol(
        outbound({ kind: IncidentKind.LINK_LOSS, batteryPercent: 99 }),
      ),
    ).toBe(ContingencyProtocol.RETURN_TO_HUB);
  });

  it('los efectos moderados y su acumulación', () => {
    const none = { burnFactor: 1, speedFactor: 1 };
    expect(applyEffect(none, IncidentKind.MOTOR_FAILURE)).toEqual({
      burnFactor: 1.15,
      speedFactor: 0.9,
    });
    const both = applyEffect(
      applyEffect(none, IncidentKind.BATTERY_DEGRADED),
      IncidentKind.COLLISION_MINOR,
    );
    expect(both.burnFactor).toBeCloseTo(1.375, 6);
    expect(applyEffect(none, IncidentKind.GPS_LOSS_MINOR)).toEqual(none);
  });

  it('la gravedad del catálogo', () => {
    expect(incidentSeverity(IncidentKind.MOTOR_FAILURE)).toBe('minor');
    expect(incidentSeverity(IncidentKind.COLLISION_MINOR)).toBe('minor');
    expect(incidentSeverity(IncidentKind.DUAL_MOTOR_FAILURE)).toBe('major');
    expect(incidentSeverity(IncidentKind.DRONE_LOST)).toBe('major');
  });
});
