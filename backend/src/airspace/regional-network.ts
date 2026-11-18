/**
 * La red regional de `context/negocio/cobertura.md`. Coordenadas de
 * municipios y corregimientos: GeoNames (vía Open-Meteo). Los nodos y los
 * puntos de Valledupar son ficticios: fuera de toda zona de
 * `regional-airspace.ts`.
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

export const MAIN_HUBS = {
  valledupar: {
    code: 'node-valledupar',
    name: 'Central Valledupar',
    municipality: 'Valledupar',
    latitude: 10.479,
    longitude: -73.235,
    elevationM: 170,
  },
  north: {
    code: 'node-north',
    name: 'Central Norte (Río Seco)',
    municipality: 'Valledupar',
    latitude: 10.6075,
    longitude: -73.2237,
    elevationM: 235,
  },
  south: {
    code: 'node-south',
    name: 'Central Sur (La Paz – San Diego)',
    municipality: 'La Paz',
    latitude: 10.355,
    longitude: -73.14,
    elevationM: 170,
  },
  west: {
    code: 'node-west',
    name: 'Central Occidente (Valencia de Jesús)',
    municipality: 'Valledupar',
    latitude: 10.3,
    longitude: -73.405,
    elevationM: 185,
  },
  codazzi: {
    code: 'node-codazzi',
    name: 'Central Codazzi',
    municipality: 'Agustín Codazzi',
    latitude: 10.042,
    longitude: -73.244,
    elevationM: 140,
  },
} satisfies Record<string, NetworkSite>;

export const ESES = {
  rosarioPumarejo: {
    code: 'ese-rosario-pumarejo',
    name: 'ESE Hospital Rosario Pumarejo de López',
    municipality: 'Valledupar',
    latitude: 10.4772,
    longitude: -73.2611,
    elevationM: 170,
  },
  arredondo: {
    code: 'ese-eduardo-arredondo',
    name: 'ESE Hospital Eduardo Arredondo Daza',
    municipality: 'Valledupar',
    latitude: 10.456,
    longitude: -73.2545,
    elevationM: 165,
  },
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

/**
 * RF-37: lugares de la región adonde piden los solicitantes simulados, con
 * la central que los alcanza. Chemesquemena y Villa Germania no están: con
 * la subida del terreno (RF-46) ningún tipo llega y vuelve con la reserva
 * (`context/negocio/cobertura.md`).
 */
export const DEMO_PLACES: Array<NetworkSite & { hubCode: string }> = [
  site(
    'dp-los-mayales',
    'Puesto de salud de Los Mayales',
    'Valledupar',
    10.451,
    -73.24,
    165,
    MAIN_HUBS.valledupar,
  ),
  site(
    'dp-la-nevada',
    'Puesto de salud de La Nevada',
    'Valledupar',
    10.495,
    -73.287,
    185,
    MAIN_HUBS.valledupar,
  ),
  site(
    'dp-primero-de-mayo',
    'Puesto de salud de Primero de Mayo',
    'Valledupar',
    10.4555,
    -73.259,
    165,
    MAIN_HUBS.valledupar,
  ),
  site(
    'dp-villa-miriam',
    'Puesto de salud de Villa Miriam',
    'Valledupar',
    10.456,
    -73.23,
    160,
    MAIN_HUBS.valledupar,
  ),
  site(
    'dp-patillal',
    'Puesto de salud de Patillal',
    'Valledupar',
    10.7064,
    -73.2123,
    513,
    MAIN_HUBS.north,
  ),
  site(
    'dp-badillo',
    'Puesto de salud de Badillo',
    'Valledupar',
    10.6314,
    -73.1279,
    200,
    MAIN_HUBS.north,
  ),
  site(
    'dp-guacoche',
    'Puesto de salud de Guacoche',
    'Valledupar',
    10.4964,
    -73.166,
    130,
    MAIN_HUBS.north,
  ),
  site(
    'dp-guacochito',
    'Puesto de salud de Guacochito',
    'Valledupar',
    10.5154,
    -73.1517,
    133,
    MAIN_HUBS.north,
  ),
  site(
    'dp-atanquez',
    'Puesto de salud de Atánquez',
    'Valledupar',
    10.6976,
    -73.3545,
    793,
    MAIN_HUBS.north,
  ),
  site(
    'dp-guatapuri',
    'Puesto de salud de Guatapurí',
    'Valledupar',
    10.7261,
    -73.3925,
    1277,
    MAIN_HUBS.north,
  ),
  site(
    'dp-media-luna',
    'Puesto de salud de Media Luna',
    'San Diego',
    10.2455,
    -73.1439,
    407,
    MAIN_HUBS.south,
  ),
  site(
    'dp-valencia',
    'Puesto de salud de Valencia de Jesús',
    'Valledupar',
    10.3017,
    -73.3945,
    185,
    MAIN_HUBS.west,
  ),
  site(
    'dp-aguas-blancas',
    'Puesto de salud de Aguas Blancas',
    'Valledupar',
    10.2253,
    -73.491,
    184,
    MAIN_HUBS.west,
  ),
  site(
    'dp-mariangola',
    'Puesto de salud de Mariangola',
    'Valledupar',
    10.1851,
    -73.5871,
    124,
    MAIN_HUBS.west,
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
): NetworkSite & { hubCode: string } {
  return {
    code,
    name,
    municipality,
    latitude,
    longitude,
    elevationM,
    hubCode: node.code,
  };
}
