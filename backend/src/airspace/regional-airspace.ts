import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { LngLat } from '../routing/routing.rules';
import { AirspaceZone, circlePolygon } from './airspace.rules';

/**
 * RF-43: las zonas legales de la demo (`context/operacion/espacio-aereo.md`).
 * Cada zona tiene el tamaño que muestra el visor de la Aerocivil, no el
 * margen completo del RAC 100: es una simplificación declarada para que la
 * red se pueda ver. Ubicaciones de la AIP para el ARP, de OpenStreetMap para
 * las pistas y, para el resto, de la lista que reunió el equipo (nov. 2026).
 */

/** ARP de SKVP según la AIP AD 2: 10°26'06.47"N, 73°14'57.83"W. */
export const SKVP_ARP: LngLat = { latitude: 10.43513, longitude: -73.2494 };

/** Anillo del aeropuerto en la demo (la norma pide 9 km). */
export const AERODROME_RADIUS_KM = 1.5;
/** Helipunto en la demo (la norma pide 3 km). */
export const HELIPORT_RADIUS_KM = 0.3;
/** Estación de policía o CAI: el círculo del visor. */
export const POLICE_RADIUS_KM = 0.1;
/** Pista agrícola: un círculo que cubre la pista. */
export const AIRSTRIP_RADIUS_KM = 0.4;

const OSM = 'OpenStreetMap (nov. 2026)';
const POLICE_LIST = 'Lista de CAI y estaciones de la Policía (equipo AirDrop)';
const TEAM_LIST = 'Ubicación reunida por el equipo AirDrop (nov. 2026)';
const ART_13 = 'RAC 100.315(a)(13)';
const DEMO_SCALE = 'tamaño del visor de la Aerocivil (demo)';

function circle(
  code: string,
  name: string,
  center: LngLat,
  radiusKm: number,
  source: string,
): AirspaceZone {
  return {
    code,
    kind: AirspaceZoneKind.PROHIBITED,
    name,
    legalBasis: `${ART_13}: ${DEMO_SCALE}`,
    source,
    polygon: circlePolygon(center, radiusKm, radiusKm >= 0.3 ? 16 : 12),
  };
}

function police(
  code: string,
  name: string,
  latitude: number,
  longitude: number,
  source = POLICE_LIST,
): AirspaceZone {
  return circle(code, name, { latitude, longitude }, POLICE_RADIUS_KM, source);
}

function airstrip(
  code: string,
  name: string,
  latitude: number,
  longitude: number,
): AirspaceZone {
  return circle(
    code,
    `Pista agrícola ${name}`,
    { latitude, longitude },
    AIRSTRIP_RADIUS_KM,
    OSM,
  );
}

/** Polígono de una instalación, a partir de sus esquinas [lon, lat]. */
function facility(
  code: string,
  name: string,
  corners: Array<[number, number]>,
): AirspaceZone {
  return {
    code,
    kind: AirspaceZoneKind.PROHIBITED,
    name,
    legalBasis: `${ART_13}: ${DEMO_SCALE}`,
    source: TEAM_LIST,
    polygon: { type: 'Polygon', coordinates: [[...corners, corners[0]]] },
  };
}

export function regionalAirspace(): AirspaceZone[] {
  return [
    {
      code: 'skvp',
      kind: AirspaceZoneKind.AERODROME,
      name: 'Aeropuerto Alfonso López Pumarejo (SKVP)',
      legalBasis:
        'RAC 100.315(a)(14): 1,5 km desde el ARP (demo; la norma pide 9 km)',
      source: 'AIP Colombia AD 2 SKVP (AMDT 67)',
      polygon: circlePolygon(SKVP_ARP, AERODROME_RADIUS_KM, 32),
    },
    // Valledupar: instalaciones grandes, con las esquinas de su terreno.
    facility('bat-la-popa', 'Batallón La Popa – Décima Brigada Blindada', [
      [-73.281, 10.4715],
      [-73.2685, 10.471],
      [-73.269, 10.4605],
      [-73.2815, 10.461],
    ]),
    facility('carcel-tramacua', 'Cárcel La Tramacúa (CPAMS Valledupar)', [
      [-73.3055, 10.4656],
      [-73.3016, 10.4654],
      [-73.3018, 10.462],
      [-73.3056, 10.4622],
    ]),
    // Con solo el área: un círculo de la misma superficie.
    circle(
      'bat-ingenieros-10',
      'Batallón de Ingenieros N.° 10 General Manuel Alberto Murillo',
      { latitude: 10.5285, longitude: -73.2495 },
      0.33,
      TEAM_LIST,
    ),
    circle(
      'sub-valledupar',
      'Subestación Valledupar (220/110 kV)',
      { latitude: 10.4435, longitude: -73.2685 },
      0.12,
      TEAM_LIST,
    ),
    circle(
      'sub-guatapuri',
      'Subestación Guatapurí (110 kV)',
      { latitude: 10.48672, longitude: -73.25798 },
      0.06,
      TEAM_LIST,
    ),
    circle(
      'solar-la-mesa',
      'Granjas solares del sector La Mesa',
      { latitude: 10.438, longitude: -73.325 },
      0.5,
      TEAM_LIST,
    ),
    // Valledupar: CAI. El de San Fernando cae dentro del anillo del
    // aeropuerto: ya está cubierto.
    police('cai-hurtado', 'CAI Hurtado', 10.5038, -73.2682),
    police('cai-san-joaquin', 'CAI San Joaquín', 10.4712, -73.2575),
    police('cai-garupal', 'CAI Garupal', 10.4785, -73.2688),
    police('cai-el-carmen', 'CAI El Carmen', 10.4715, -73.2435),
    police('cai-gobernacion', 'CAI Gobernación', 10.4762, -73.2465),
    police('cai-primero-de-mayo', 'CAI Primero de Mayo', 10.4618, -73.253),
    police('cai-mayales', 'CAI Mayales', 10.4535, -73.2415),
    // Municipios.
    police('pol-la-paz', 'Estación de policía de La Paz', 10.3845, -73.1722),
    police(
      'pol-san-diego',
      'Estación de policía de San Diego',
      10.3364,
      -73.1815,
    ),
    police('pol-manaure', 'Estación de policía de Manaure', 10.3918, -73.0332),
    police(
      'pol-pueblo-bello',
      'Estación de policía de Pueblo Bello',
      10.4162,
      -73.5855,
    ),
    police(
      'pol-codazzi',
      'Estación de policía de Agustín Codazzi',
      10.0385,
      -73.2375,
    ),
    police(
      'pol-atanquez',
      'Estación de policía de Atánquez',
      10.7015,
      -73.3485,
    ),
    // Corregimientos de Valledupar.
    police(
      'pol-valencia',
      'Subestación de policía de Valencia de Jesús',
      10.3125,
      -73.4018,
    ),
    police(
      'pol-aguas-blancas',
      'Subestación de policía de Aguas Blancas',
      10.2445,
      -73.4852,
    ),
    police(
      'pol-mariangola',
      'Subestación de policía de Mariangola',
      10.1812,
      -73.5625,
    ),
    police(
      'pol-patillal',
      'Subestación de policía de Patillal',
      10.6655,
      -73.1492,
    ),
    police(
      'pol-badillo',
      'Subestación de policía de Badillo',
      10.6318,
      -73.1115,
    ),
    circle(
      'bam-7-perija',
      'Batallón de Alta Montaña N.° 7 Mayor Raúl Guillermo Mahecha',
      { latitude: 9.985, longitude: -73.065 },
      0.28,
      TEAM_LIST,
    ),
    // Pistas agrícolas cerca de rutas reales.
    airstrip('pista-codazzi', 'Codazzi', 10.11143, -73.2257),
    airstrip('pista-las-flores', 'Las Flores', 10.1026, -73.23302),
    airstrip('pista-ana-maria', 'Ana María', 10.0375, -73.28361),
    airstrip('pista-aguas-blancas', 'Aguasblancas', 10.20756, -73.47514),
    airstrip('pista-convencion', 'Convención', 10.26407, -73.41425),
    airstrip('pista-madaci', 'Madaci', 10.3276, -73.37257),
  ];
}
