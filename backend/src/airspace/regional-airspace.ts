import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { LngLat } from '../routing/routing.rules';
import {
  AirspaceZone,
  PactedSite,
  circlePolygon,
  gatewayToward,
} from './airspace.rules';
import { DELIVERY_POINTS, ESES, NODES, NetworkSite } from './regional-network';

/**
 * RF-43: las zonas legales de la demo (`context/operacion/espacio-aereo.md`).
 * Ubicaciones de OpenStreetMap (consulta de noviembre de 2026) y de la AIP
 * para el ARP. No son oficiales: una operación real las tomaría del visor de
 * la Aerocivil.
 */

/** ARP de SKVP según la AIP AD 2: 10°26'06.47"N, 73°14'57.83"W. */
export const SKVP_ARP: LngLat = { latitude: 10.43513, longitude: -73.2494 };

export const AERODROME_RADIUS_KM = 9;
export const HELIPORT_RADIUS_KM = 3;
/** RAC 100.315(a)(13): 2 km desde el perímetro. */
export const SECURITY_MARGIN_KM = 2;
/** Sin perímetro oficial, se supone una instalación de 300 m de radio. */
export const NOMINAL_PERIMETER_KM = 0.3;

const SECURITY_RADIUS_KM = SECURITY_MARGIN_KM + NOMINAL_PERIMETER_KM;
const OSM = 'OpenStreetMap (nov. 2026)';
const ART_13 = 'RAC 100.315(a)(13)';

function prohibited(code: string, name: string, center: LngLat): AirspaceZone {
  return {
    code,
    kind: AirspaceZoneKind.PROHIBITED,
    name,
    legalBasis: `${ART_13}: 2 km desde el perímetro`,
    source: OSM,
    polygon: circlePolygon(center, SECURITY_RADIUS_KM, 16),
    gateway: null,
    sites: [],
  };
}

function policeStation(
  code: string,
  name: string,
  center: LngLat,
  servedFrom: NetworkSite,
  sites: PactedSite[],
): AirspaceZone {
  return {
    code,
    kind: AirspaceZoneKind.COORDINATED,
    name,
    legalBasis: `${ART_13}; desviación de la categoría específica (100.410(a)(10))`,
    source: OSM,
    polygon: circlePolygon(center, SECURITY_RADIUS_KM, 16),
    gateway: gatewayToward(center, SECURITY_RADIUS_KM, servedFrom),
    sites,
  };
}

function caution(code: string, name: string, center: LngLat): AirspaceZone {
  return {
    code,
    kind: AirspaceZoneKind.CAUTION,
    name,
    legalBasis:
      'Pista privada sin ARP en la AIP: se consulta en el visor de la Aerocivil',
    source: OSM,
    polygon: circlePolygon(center, 0.5, 8),
    gateway: null,
    sites: [],
  };
}

function asSite(site: NetworkSite): PactedSite {
  return {
    name: site.name,
    latitude: site.latitude,
    longitude: site.longitude,
  };
}

function point(code: string): PactedSite {
  const found = DELIVERY_POINTS.find((entry) => entry.code === code);
  if (!found) {
    throw new Error(`No existe el punto ${code}`);
  }
  return asSite(found);
}

function ring(points: Array<[number, number]>): AirspaceZone['polygon'] {
  return { type: 'Polygon', coordinates: [[...points, points[0]]] };
}

export function regionalAirspace(): AirspaceZone[] {
  return [
    {
      code: 'skvp',
      kind: AirspaceZoneKind.AERODROME,
      name: 'Aeropuerto Alfonso López Pumarejo (SKVP)',
      legalBasis: 'RAC 100.315(a)(14): 9 km desde el ARP',
      source: 'AIP Colombia AD 2 SKVP (AMDT 67)',
      polygon: circlePolygon(SKVP_ARP, AERODROME_RADIUS_KM, 32),
      gateway: null,
      sites: [],
    },
    {
      code: 'skvp-helipad',
      kind: AirspaceZoneKind.HELIPORT,
      name: 'Helipunto junto a la pista de SKVP',
      legalBasis: 'RAC 100.315(a)(15): 3 km desde el punto de referencia',
      source: OSM,
      polygon: circlePolygon(
        { latitude: 10.43261, longitude: -73.24885 },
        HELIPORT_RADIUS_KM,
        16,
      ),
      gateway: null,
      sites: [],
    },
    {
      code: 'urban-valledupar',
      kind: AirspaceZoneKind.URBAN,
      name: 'Casco urbano de Valledupar',
      legalBasis: 'RAC 100.220(b): en zona urbana solo VLOS',
      source: 'Trazado aproximado del casco urbano',
      polygon: ring([
        [-73.3, 10.42],
        [-73.215, 10.42],
        [-73.205, 10.47],
        [-73.225, 10.515],
        [-73.285, 10.515],
        [-73.31, 10.47],
      ]),
      gateway: null,
      sites: [],
    },
    prohibited('bat-la-popa', 'Batallón La Popa – Décima Brigada Blindada', {
      latitude: 10.46633,
      longitude: -73.27341,
    }),
    prohibited('carcel-tramacua', 'Cárcel La Tramacúa (EPAMSCAS Valledupar)', {
      latitude: 10.44922,
      longitude: -73.30887,
    }),
    prohibited('militar-norte', 'Instalación militar al norte de Valledupar', {
      latitude: 10.51728,
      longitude: -73.24875,
    }),
    prohibited('sub-valledupar', 'Subestación Valledupar', {
      latitude: 10.4587,
      longitude: -73.2728,
    }),
    prohibited('sub-guatapuri', 'Subestación Guatapurí', {
      latitude: 10.48672,
      longitude: -73.25798,
    }),
    prohibited('planta-sur', 'Planta eléctrica al sur de Valledupar', {
      latitude: 10.38182,
      longitude: -73.1947,
    }),
    prohibited('planta-san-diego', 'Planta eléctrica cerca de San Diego', {
      latitude: 10.3349,
      longitude: -73.22822,
    }),
    prohibited('cerro-aguacil', 'Cerro El Aguacil (instalación militar)', {
      latitude: 10.50739,
      longitude: -73.55696,
    }),
    prohibited('bam-perija', 'Batallón de Alta Montaña (Serranía del Perijá)', {
      latitude: 10.02971,
      longitude: -73.04506,
    }),
    policeStation(
      'pol-san-diego',
      'Estación de policía de San Diego',
      { latitude: 10.32999, longitude: -73.18429 },
      NODES.south,
      [asSite(ESES.sanDiego)],
    ),
    policeStation(
      'pol-manaure',
      'Estación de policía de Manaure',
      { latitude: 10.38873, longitude: -73.02976 },
      NODES.south,
      [asSite(ESES.manaure)],
    ),
    policeStation(
      'pol-pueblo-bello',
      'Estación de policía de Pueblo Bello',
      { latitude: 10.41559, longitude: -73.58651 },
      NODES.west,
      [asSite(ESES.puebloBello)],
    ),
    policeStation(
      'pol-codazzi',
      'Estación de policía de Codazzi',
      { latitude: 10.02734, longitude: -73.23679 },
      NODES.codazzi,
      [asSite(ESES.codazzi)],
    ),
    {
      code: 'resguardo-kankuamo',
      kind: AirspaceZoneKind.COORDINATED,
      name: 'Resguardo kankuamo (Atánquez, Guatapurí, Chemesquemena)',
      legalBasis:
        'Decreto 1500 de 2018 (Línea Negra). Incluye la estación de Atánquez y la instalación militar de Guatapurí (RAC 100.315(a)(13))',
      source:
        'Polígono ilustrativo; el oficial es de la Agencia Nacional de Tierras',
      polygon: ring([
        [-73.43, 10.665],
        [-73.33, 10.665],
        [-73.32, 10.72],
        [-73.36, 10.765],
        [-73.43, 10.755],
      ]),
      gateway: { latitude: 10.655, longitude: -73.33 },
      sites: [
        point('dp-atanquez'),
        point('dp-guatapuri'),
        point('dp-chemesquemena'),
      ],
    },
    {
      code: 'resguardo-arhuaco',
      kind: AirspaceZoneKind.COORDINATED,
      name: 'Resguardo arhuaco (Nabusímake)',
      legalBasis: 'Decreto 1500 de 2018 (Línea Negra)',
      source:
        'Polígono ilustrativo; el oficial es de la Agencia Nacional de Tierras',
      polygon: ring([
        [-73.64, 10.55],
        [-73.55, 10.55],
        [-73.55, 10.62],
        [-73.64, 10.62],
      ]),
      // Sin punto pactado: Nabusímake queda fuera de la red (cobertura.md).
      gateway: null,
      sites: [],
    },
    caution('pista-madaci', 'Pista Madaci', {
      latitude: 10.3276,
      longitude: -73.37257,
    }),
    caution('pista-convencion', 'Pista Convención', {
      latitude: 10.26407,
      longitude: -73.41425,
    }),
    caution('pista-aguas-blancas', 'Pista Aguasblancas', {
      latitude: 10.20756,
      longitude: -73.47514,
    }),
    caution('pista-maria-angola', 'Pista María Angola', {
      latitude: 10.18625,
      longitude: -73.55403,
    }),
    caution('pista-codazzi-no', 'Pista Codazzi Noroeste', {
      latitude: 10.133,
      longitude: -73.22797,
    }),
  ];
}
