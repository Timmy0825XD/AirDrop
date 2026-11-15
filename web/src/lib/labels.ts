/** Textos en español de Colombia para lo que Nest manda como código. */

export const HUB_TYPE: Record<string, string> = {
  hospital: "Hospital",
  clinic: "Clínica",
  pharmacy: "Farmacia",
  blood_bank: "Banco de sangre",
  vaccination: "Vacunación",
};

/** RF-06: el papel de la central en la red. */
export const NETWORK_ROLE: Record<string, string> = {
  node: "Nodo",
  ese: "ESE",
};

/** RF-43: los tipos de zona legal. */
export const AIRSPACE_KIND: Record<string, string> = {
  aerodrome: "Aeródromo",
  prohibited: "Prohibida",
  heliport: "Helipuerto",
  coordinated: "Coordinada",
  urban: "Urbana",
  caution: "Precaución",
};

/** RF-48: el estado de la identificación remota. */
export const REMOTE_ID_STATUS: Record<string, string> = {
  mission: "En misión",
  returning: "Regreso",
  link_lost: "Sin enlace",
  emergency: "Emergencia",
};

/** RF-49: los tres tipos de dron. */
export const DRONE_KIND: Record<string, string> = {
  rapid: "Colibrí",
  balanced: "Garza",
  cargo: "Cóndor",
};

export const DRONE_STATUS: Record<string, string> = {
  available: "Disponible",
  in_mission: "En misión",
  maintenance: "Mantenimiento",
  grounded: "En tierra, espera rescate",
  out_of_service: "Fuera de servicio",
};

export const PHASE: Record<string, string> = {
  takeoff: "Despegue",
  transition: "Transición",
  cruise: "Crucero",
  descent: "Descenso",
  landing: "Aterrizaje",
  landed: "En tierra",
  unloading: "Retiro del medicamento",
};

export const ORDER_STATUS: Record<string, string> = {
  pending_load: "Pendiente de carga",
  in_flight: "En vuelo",
  awaiting_delivery: "Esperando el código",
  delivered: "Entregado",
  returning: "Regresando con el paquete",
  returned: "Devuelto",
};

export const QUEUE_STATUS: Record<string, string> = {
  received: "Recibidos",
  assigned: "Asignados",
  pending_load: "Por cargar",
  in_flight: "En vuelo",
  awaiting_delivery: "Esperando código",
  returning: "Regresando",
};

export const SALE_TYPE: Record<string, string> = {
  over_the_counter: "Venta libre",
  prescription: "Con fórmula",
  special_control: "Control especial",
};

export const label = (map: Record<string, string>, key: string | null) =>
  key ? (map[key] ?? key) : "—";

/** "12 min", "45 s": la ETA que manda el simulador, en segundos. */
export function formatEta(seconds: number | null): string {
  if (seconds == null) return "—";
  if (seconds < 60) return `${Math.max(0, Math.round(seconds))} s`;
  return `${Math.round(seconds / 60)} min`;
}

export function daysUntil(isoDate: string, now = Date.now()): number {
  const target = new Date(`${isoDate}T00:00:00-05:00`).getTime();
  return Math.ceil((target - now) / 86_400_000);
}

/** Alertas de vuelo (`radar-alert`, `GET /control/alerts`). */
export const ALERT_KIND: Record<string, string> = {
  battery_critical: "Batería crítica",
  failure: "Falla",
  cold_chain: "Frío fuera de rango",
  wind_limit: "Viento sobre el límite",
  emergency_landing: "Aterrizaje de emergencia",
};

/** RF-32: los tipos de clima. */
export const WEATHER_KIND: Record<string, string> = {
  wind: "Viento",
  rain: "Lluvia",
  storm: "Tormenta",
  fog: "Niebla",
};

/** RF-34: lo que el sistema hizo con el dron. */
export const PROTOCOL: Record<string, string> = {
  continue: "Sigue su misión",
  return_to_hub: "Vuelve a la central",
  emergency_landing: "Aterrizaje de emergencia",
  crash: "Cayó",
  lost: "Perdido",
};

/** Minutos que faltan (hora simulada) para `iso`; nunca negativo. */
export function minutesLeft(iso: string, now: number): number {
  return Math.max(0, Math.ceil((Date.parse(iso) - now) / 60_000));
}
