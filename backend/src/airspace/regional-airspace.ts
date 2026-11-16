import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { LngLat } from '../routing/routing.rules';
import { AirspaceZone, circlePolygon } from './airspace.rules';

/**
 * RF-43: las zonas legales de la demo (`context/operacion/espacio-aereo.md`).
 * Cada zona tiene el tamaño que muestra el visor de la Aerocivil, no el
 * margen completo del RAC 100: es una simplificación declarada para que la
 * red se pueda ver. Ubicaciones de OpenStreetMap (nov. 2026), de la AIP para
 * el ARP y de la lista de CAI de Valledupar que reunió el equipo.
 */

/** ARP de SKVP según la AIP AD 2: 10°26'06.47"N, 73°14'57.83"W. */
export const SKVP_ARP: LngLat = { latitude: 10.43513, longitude: -73.2494 };

/** Anillo del aeropuerto en la demo (la norma pide 9 km). */
export const AERODROME_RADIUS_KM = 1.5;
/** Helipunto en la demo (la norma pide 3 km). */
export const HELIPORT_RADIUS_KM = 0.3;
/** Estación de policía o CAI: el círculo del visor. */
export const POLICE_RADIUS_KM = 0.1;
/** Fuerte o puesto militar menor. */
export const MILITARY_POST_RADIUS_KM = 0.15;
/** Pista agrícola: un círculo que cubre la pista. */
export const AIRSTRIP_RADIUS_KM = 0.4;

const OSM = 'OpenStreetMap (nov. 2026)';
const POLICE_LIST = 'Lista de CAI y estaciones de la Policía (equipo AirDrop)';
const VISOR = 'Ubicado en el poblado con el visor de la Aerocivil';
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
    source: OSM,
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
    // Valledupar: instalaciones grandes (polígonos de unos 400 × 300 m).
    facility('bat-la-popa', 'Batallón La Popa – Décima Brigada Blindada', [
      [-73.2755, 10.465],
      [-73.2718, 10.465],
      [-73.2718, 10.4677],
      [-73.2755, 10.4677],
    ]),
    facility('carcel-tramacua', 'Cárcel La Tramacúa (CPAMS Valledupar)', [
      [-73.3103, 10.4481],
      [-73.3075, 10.4481],
      [-73.3075, 10.4503],
      [-73.3103, 10.4503],
    ]),
    circle(
      'militar-norte',
      'Instalación militar al norte de Valledupar',
      { latitude: 10.51728, longitude: -73.24875 },
      MILITARY_POST_RADIUS_KM,
      OSM,
    ),
    circle(
      'sub-valledupar',
      'Subestación Valledupar',
      { latitude: 10.4587, longitude: -73.2728 },
      POLICE_RADIUS_KM,
      OSM,
    ),
    circle(
      'sub-guatapuri',
      'Subestación Guatapurí',
      { latitude: 10.48672, longitude: -73.25798 },
      POLICE_RADIUS_KM,
      OSM,
    ),
    circle(
      'planta-sur',
      'Planta eléctrica al sur de Valledupar',
      { latitude: 10.38182, longitude: -73.1947 },
      MILITARY_POST_RADIUS_KM,
      OSM,
    ),
    // Valledupar: CAI. Uno pegado a otra zona o dentro del anillo del
    // aeropuerto no se dibuja: ya está cubierto.
    police('cai-hurtado', 'CAI Hurtado', 10.501, -73.2681),
    police('cai-san-joaquin', 'CAI San Joaquín', 10.4764, -73.2558),
    police('cai-garupal', 'CAI Garupal', 10.4748, -73.2645),
    police('cai-el-carmen', 'CAI El Carmen', 10.4712, -73.2608),
    police('cai-gobernacion', 'CAI Gobernación', 10.4705, -73.2494),
    police('cai-primero-de-mayo', 'CAI Primero de Mayo', 10.4578, -73.2562),
    police('cai-mayales', 'CAI Mayales', 10.4535, -73.2428),
    police('cai-san-fernando', 'CAI San Fernando', 10.4405, -73.2355),
    // Pueblos y corregimientos.
    police('pol-la-paz', 'Estación de policía de La Paz', 10.3854, -73.1722),
    police(
      'pol-san-diego',
      'Estación de policía de San Diego',
      10.3364,
      -73.1815,
    ),
    police('pol-manaure', 'Estación de policía de Manaure', 10.3916, -73.0322),
    police(
      'pol-pueblo-bello',
      'Estación de policía de Pueblo Bello',
      10.4167,
      -73.5833,
    ),
    police(
      'pol-codazzi',
      'Estación de policía de Codazzi',
      10.02734,
      -73.23679,
      OSM,
    ),
    police(
      'pol-atanquez',
      'Estación de policía de Atánquez',
      10.69706,
      -73.352,
      OSM,
    ),
    police(
      'pol-valencia',
      'Subestación de policía de Valencia de Jesús',
      10.301,
      -73.3915,
      VISOR,
    ),
    police(
      'pol-aguas-blancas',
      'Subestación de policía de Aguas Blancas',
      10.228,
      -73.495,
      VISOR,
    ),
    police(
      'pol-mariangola',
      'Subestación de policía de Mariangola',
      10.187,
      -73.589,
      VISOR,
    ),
    police(
      'pol-patillal',
      'Subestación de policía de Patillal',
      10.709,
      -73.21,
      VISOR,
    ),
    police(
      'pol-badillo',
      'Subestación de policía de Badillo',
      10.634,
      -73.126,
      VISOR,
    ),
    circle(
      'militar-guatapuri',
      'Instalación militar de Guatapurí',
      { latitude: 10.72705, longitude: -73.38933 },
      MILITARY_POST_RADIUS_KM,
      OSM,
    ),
    circle(
      'bam-perija',
      'Batallón de Alta Montaña (Serranía del Perijá)',
      { latitude: 10.02971, longitude: -73.04506 },
      MILITARY_POST_RADIUS_KM,
      OSM,
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
