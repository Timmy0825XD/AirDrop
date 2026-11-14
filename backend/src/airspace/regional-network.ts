/**
 * La red regional de `context/negocio/cobertura.md`. Coordenadas de
 * municipios y corregimientos: GeoNames (vía Open-Meteo). Los nodos son
 * instalaciones ficticias de AirDrop: fuera del anillo de 9 km del ARP y a
 * más de 2 km de toda instalación de `regional-airspace.ts`.
 */

export type NetworkSite = {
  code: string;
  name: string;
  municipality: string;
  latitude: number;
  longitude: number;
  /** Elevación del registro, en metros sobre el nivel del mar. */
  elevationM: number;
};

export const NODES = {
  north: {
    code: 'node-north',
    name: 'Nodo Norte (Río Seco)',
    municipality: 'Valledupar',
    latitude: 10.6075,
    longitude: -73.2237,
    elevationM: 235,
  },
  south: {
    code: 'node-south',
    name: 'Nodo Sur (La Paz – San Diego)',
    municipality: 'La Paz',
    latitude: 10.355,
    longitude: -73.14,
    elevationM: 170,
  },
  west: {
    code: 'node-west',
    name: 'Nodo Occidente (Valencia de Jesús)',
    municipality: 'Valledupar',
    latitude: 10.3,
    longitude: -73.405,
    elevationM: 185,
  },
  codazzi: {
    code: 'node-codazzi',
    name: 'Nodo Codazzi',
    municipality: 'Agustín Codazzi',
    latitude: 10.055,
    longitude: -73.255,
    elevationM: 140,
  },
} satisfies Record<string, NetworkSite>;

export const ESES = {
  laPaz: {
    code: 'ese-la-paz',
    name: 'ESE Hospital de La Paz',
    municipality: 'La Paz',
    latitude: 10.3844,
    longitude: -73.1733,
    elevationM: 152,
  },
  sanDiego: {
    code: 'ese-san-diego',
    name: 'ESE Hospital de San Diego',
    municipality: 'San Diego',
    latitude: 10.3338,
    longitude: -73.1805,
    elevationM: 180,
  },
  manaure: {
    code: 'ese-manaure',
    name: 'ESE Hospital de Manaure',
    municipality: 'Manaure Balcón del Cesar',
    latitude: 10.3928,
    longitude: -73.0325,
    elevationM: 726,
  },
  puebloBello: {
    code: 'ese-pueblo-bello',
    name: 'ESE Hospital de Pueblo Bello',
    municipality: 'Pueblo Bello',
    latitude: 10.4171,
    longitude: -73.5804,
    elevationM: 1108,
  },
  codazzi: {
    code: 'ese-codazzi',
    name: 'ESE Hospital de Agustín Codazzi',
    municipality: 'Agustín Codazzi',
    latitude: 10.0367,
    longitude: -73.2356,
    elevationM: 136,
  },
} satisfies Record<string, NetworkSite>;

/** RF-45: puntos de entrega, con el nodo que los atiende. */
export const DELIVERY_POINTS: Array<NetworkSite & { nodeCode: string }> = [
  site(
    'dp-patillal',
    'Puesto de salud de Patillal',
    'Valledupar',
    10.7064,
    -73.2123,
    513,
    NODES.north,
  ),
  site(
    'dp-badillo',
    'Puesto de salud de Badillo',
    'Valledupar',
    10.6314,
    -73.1279,
    200,
    NODES.north,
  ),
  site(
    'dp-guacoche',
    'Puesto de salud de Guacoche',
    'Valledupar',
    10.4964,
    -73.166,
    130,
    NODES.north,
  ),
  site(
    'dp-guacochito',
    'Puesto de salud de Guacochito',
    'Valledupar',
    10.5154,
    -73.1517,
    133,
    NODES.north,
  ),
  site(
    'dp-atanquez',
    'Puesto de salud de Atánquez',
    'Valledupar',
    10.6976,
    -73.3545,
    793,
    NODES.north,
  ),
  site(
    'dp-guatapuri',
    'Puesto de salud de Guatapurí',
    'Valledupar',
    10.7261,
    -73.3925,
    1277,
    NODES.north,
  ),
  site(
    'dp-chemesquemena',
    'Puesto de salud de Chemesquemena',
    'Valledupar',
    10.7132,
    -73.4007,
    1427,
    NODES.north,
  ),
  site(
    'dp-media-luna',
    'Puesto de salud de Media Luna',
    'San Diego',
    10.2455,
    -73.1439,
    407,
    NODES.south,
  ),
  site(
    'dp-valencia',
    'Puesto de salud de Valencia de Jesús',
    'Valledupar',
    10.3017,
    -73.3945,
    185,
    NODES.west,
  ),
  site(
    'dp-aguas-blancas',
    'Puesto de salud de Aguas Blancas',
    'Valledupar',
    10.2253,
    -73.491,
    184,
    NODES.west,
  ),
  site(
    'dp-mariangola',
    'Puesto de salud de Mariangola',
    'Valledupar',
    10.1851,
    -73.5871,
    124,
    NODES.west,
  ),
  site(
    'dp-villa-germania',
    'Puesto de salud de Villa Germania',
    'Valledupar',
    10.2669,
    -73.7151,
    614,
    NODES.west,
  ),
];

function site(
  code: string,
  name: string,
  municipality: string,
  latitude: number,
  longitude: number,
  elevationM: number,
  node: NetworkSite,
): NetworkSite & { nodeCode: string } {
  return {
    code,
    name,
    municipality,
    latitude,
    longitude,
    elevationM,
    nodeCode: node.code,
  };
}
