/**
 * RF-35: un pedido despachado otra vez tras un incidente tiene una misión por
 * intento. La vigente es la última que empezó.
 */
export function latestMissionByOrder<
  T extends { orderId: string; startedAt: Date },
>(missions: T[]): Map<string, T> {
  const latest = new Map<string, T>();
  for (const mission of missions) {
    const known = latest.get(mission.orderId);
    if (
      !known ||
      new Date(mission.startedAt).getTime() >
        new Date(known.startedAt).getTime()
    ) {
      latest.set(mission.orderId, mission);
    }
  }
  return latest;
}
