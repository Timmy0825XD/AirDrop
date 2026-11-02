/**
 * Cuenta de batería del Wingcopter 198 simulado. La usan el reloj de vuelo
 * (cuánto gasta cada tick) y el motor de decisión (si el vuelo alcanza), para
 * que los dos hablen de la misma física.
 */

/** Porcentajes fijos de cada fase vertical. El crucero gasta según el alcance. */
export const TAKEOFF_BATTERY_PERCENT = 3;
export const TRANSITION_BATTERY_PERCENT = 1;
export const DESCENT_BATTERY_PERCENT = 1;
export const LANDING_BATTERY_PERCENT = 3;

/** Debajo de este nivel sale la alerta crítica; también es la reserva al volver. */
export const CRITICAL_BATTERY_PERCENT = 20;

/** Lo que cuestan despegue, transición, descenso y aterrizaje en un tramo: 8 %. */
export const VERTICAL_BATTERY_PER_LEG =
  TAKEOFF_BATTERY_PERCENT +
  TRANSITION_BATTERY_PERCENT +
  DESCENT_BATTERY_PERCENT +
  LANDING_BATTERY_PERCENT;

/** Gasto del crucero: recorrer todo el alcance del modelo cuesta el 100 %. */
export function cruiseBatteryPercent(
  distanceKm: number,
  maxRangeKm: number,
): number {
  return maxRangeKm > 0 ? (distanceKm / maxRangeKm) * 100 : 100;
}

/** Un tramo completo: fases verticales más crucero. */
export function legBatteryPercent(
  distanceKm: number,
  maxRangeKm: number,
): number {
  return (
    VERTICAL_BATTERY_PER_LEG + cruiseBatteryPercent(distanceKm, maxRangeKm)
  );
}

/**
 * RF-11: la batería que pide una misión. Ida y regreso por el mismo corredor
 * (si nadie recibe, el dron vuelve con el paquete) y aterrizar todavía con la
 * reserva crítica. La espera en destino no gasta batería en el simulador.
 */
export function missionBatteryPercent(
  distanceKm: number,
  maxRangeKm: number,
): number {
  return (
    2 * legBatteryPercent(distanceKm, maxRangeKm) + CRITICAL_BATTERY_PERCENT
  );
}

/** Ida más larga que cabe con la batería llena: 35,2 km para el Wingcopter 198. */
export function maxOneWayKm(maxRangeKm: number, batteryPercent = 100): number {
  const cruiseBudget =
    (batteryPercent - CRITICAL_BATTERY_PERCENT) / 2 - VERTICAL_BATTERY_PER_LEG;
  return Math.max(0, (cruiseBudget / 100) * maxRangeKm);
}
