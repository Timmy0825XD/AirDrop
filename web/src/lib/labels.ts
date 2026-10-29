/** Textos en español de Colombia para lo que Nest manda como código. */

export const HUB_TYPE: Record<string, string> = {
  hospital: "Hospital",
  clinic: "Clínica",
  pharmacy: "Farmacia",
  blood_bank: "Banco de sangre",
  vaccination: "Vacunación",
};

export const DRONE_STATUS: Record<string, string> = {
  available: "Disponible",
  in_mission: "En misión",
  maintenance: "Mantenimiento",
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
