/**
 * La red regional de `context/negocio/cobertura.md`. Coordenadas de
 * las centrales: la sede real de cada hospital o puesto de salud, fuera de
 * toda zona de `regional-airspace.ts`. En Manaure y Pueblo Bello el hospital
 * queda pegado a la estación de policía: su dronpuerto está a 200 m de ella. Lugares de la demo: GeoNames (vía
 * Open-Meteo).
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

function hub(
  code: string,
  name: string,
  municipality: string,
  latitude: number,
  longitude: number,
  elevationM: number,
): NetworkSite {
  return { code, name, municipality, latitude, longitude, elevationM };
}

/**
 * Las 12 centrales de la demo: cuatro en Valledupar, una en cada municipio
 * y una en cada corregimiento. Todas despegan, atienden a personas y
 * abastecen a otras centrales.
 */
export const HUB_SITES = {
  rosarioPumarejo: hub(
    'hub-rosario-pumarejo',
    'Hospital Rosario Pumarejo de López',
    'Valledupar',
    10.4682,
    -73.2558,
    170,
  ),
  arredondo: hub(
    'hub-eduardo-arredondo',
    'Hospital Eduardo Arredondo Daza',
    'Valledupar',
    10.4485,
    -73.2589,
    165,
  ),
  laNevada: hub(
    'hub-la-nevada',
    'Centro de Salud La Nevada',
    'Valledupar',
    10.4831,
    -73.2836,
    170,
  ),
  elCarmen: hub(
    'hub-el-carmen',
    'Centro de Salud El Carmen',
    'Valledupar',
    10.4714,
    -73.2415,
    160,
  ),
  laPaz: hub(
    'hub-la-paz',
    'Hospital Marino Zuleta Ramírez',
    'La Paz',
    10.3861,
    -73.1731,
    152,
  ),
  sanDiego: hub(
    'hub-san-diego',
    'Hospital El Socorro',
    'San Diego',
    10.3325,
    -73.1808,
    180,
  ),
  manaure: hub(
    'hub-manaure',
    'Hospital José Antonio Socarrás Sánchez',
    'Manaure Balcón del Cesar',
    10.3905,
    -73.0345,
    726,
  ),
  puebloBello: hub(
    'hub-pueblo-bello',
    'Hospital Camilo Villazón Pumarejo',
    'Pueblo Bello',
    10.4149,
    -73.5842,
    1108,
  ),
  codazzi: hub(
    'hub-codazzi',
    'Hospital Agustín Codazzi',
    'Agustín Codazzi',
    10.0367,
    -73.2369,
    136,
  ),
  rioSeco: hub(
    'hub-rio-seco',
    'Puesto de Salud de Río Seco',
    'Valledupar',
    10.6047,
    -73.2228,
    235,
  ),
  valencia: hub(
    'hub-valencia-de-jesus',
    'Puesto de Salud de Valencia de Jesús',
    'Valledupar',
    10.3,
    -73.4,
    185,
  ),
  mediaLuna: hub(
    'hub-media-luna',
    'Puesto de Salud de Media Luna',
    'San Diego',
    10.2439,
    -73.1414,
    407,
  ),
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
    HUB_SITES.arredondo,
  ),
  site(
    'dp-la-nevada',
    'Puesto de salud de La Nevada',
    'Valledupar',
    10.495,
    -73.287,
    185,
    HUB_SITES.laNevada,
  ),
  site(
    'dp-primero-de-mayo',
    'Puesto de salud de Primero de Mayo',
    'Valledupar',
    10.4555,
    -73.259,
    165,
    HUB_SITES.arredondo,
  ),
  site(
    'dp-villa-miriam',
    'Puesto de salud de Villa Miriam',
    'Valledupar',
    10.456,
    -73.23,
    160,
    HUB_SITES.elCarmen,
  ),
  site(
    'dp-patillal',
    'Puesto de salud de Patillal',
    'Valledupar',
    10.7064,
    -73.2123,
    513,
    HUB_SITES.rioSeco,
  ),
  site(
    'dp-badillo',
    'Puesto de salud de Badillo',
    'Valledupar',
    10.6314,
    -73.1279,
    200,
    HUB_SITES.rioSeco,
  ),
  site(
    'dp-guacoche',
    'Puesto de salud de Guacoche',
    'Valledupar',
    10.4964,
    -73.166,
    130,
    HUB_SITES.rioSeco,
  ),
  site(
    'dp-guacochito',
    'Puesto de salud de Guacochito',
    'Valledupar',
    10.5154,
    -73.1517,
    133,
    HUB_SITES.rioSeco,
  ),
  site(
    'dp-atanquez',
    'Puesto de salud de Atánquez',
    'Valledupar',
    10.6976,
    -73.3545,
    793,
    HUB_SITES.rioSeco,
  ),
  site(
    'dp-guatapuri',
    'Puesto de salud de Guatapurí',
    'Valledupar',
    10.7261,
    -73.3925,
    1277,
    HUB_SITES.rioSeco,
  ),
  site(
    'dp-aguas-blancas',
    'Puesto de salud de Aguas Blancas',
    'Valledupar',
    10.2253,
    -73.491,
    184,
    HUB_SITES.valencia,
  ),
  site(
    'dp-mariangola',
    'Puesto de salud de Mariangola',
    'Valledupar',
    10.1851,
    -73.5871,
    124,
    HUB_SITES.valencia,
  ),
];

function site(
  code: string,
  name: string,
  municipality: string,
  latitude: number,
  longitude: number,
  elevationM: number,
  hub: NetworkSite,
): NetworkSite & { hubCode: string } {
  return {
    code,
    name,
    municipality,
    latitude,
    longitude,
    elevationM,
    hubCode: hub.code,
  };
}
