import { HubStatus } from '../common/enums/hub-status.enum';
import { LngLat, haversineKm } from '../routing/routing.rules';

export const DELIVERY_POINT_NOT_FOUND = 'El punto de entrega no existe.';
export const DELIVERY_POINT_UNAVAILABLE =
  'Ese punto de entrega no está disponible ahora. Elige otro.';
export const NO_POINT_IN_REACH =
  'No hay un punto de entrega activo al alcance de un nodo. Puedes recoger el medicamento en una central cercana.';
export const NO_POINT_IN_CIRCLE =
  'No hay puntos de entrega activos dentro del círculo.';

/** RU-02: qué le dice la app al solicitante según dónde está. */
export enum CoverageStatus {
  COVERED = 'covered',
  /** Ningún punto activo con su nodo activo. */
  NO_POINT = 'no_point',
}

type PointLike = LngLat & {
  active: boolean;
  hubId: string | null;
  name: string;
};

/**
 * RF-45: un punto sirve si está activo y su nodo existe y está activo. El
 * motor puede despachar desde otro nodo, pero un punto sin el suyo queda
 * fuera de la lista para no prometer una red que hoy no está.
 */
export function isAvailable(
  point: PointLike,
  hubStatus: Map<string, HubStatus>,
): boolean {
  return (
    point.active &&
    point.hubId != null &&
    hubStatus.get(point.hubId) === HubStatus.ACTIVE
  );
}

/** Los puntos del más cercano al más lejano, con la distancia en km. */
export function rankByDistance<T extends PointLike>(
  points: T[],
  from: LngLat | null,
): Array<T & { distanceKm: number | null }> {
  const rows = points.map((point) => ({
    ...point,
    distanceKm: from ? Math.round(haversineKm(from, point) * 100) / 100 : null,
  }));
  return rows.sort((left, right) => {
    if (left.distanceKm != null && right.distanceKm != null) {
      if (left.distanceKm !== right.distanceKm) {
        return left.distanceKm - right.distanceKm;
      }
    }
    return left.name.localeCompare(right.name);
  });
}

export function coverageMessage(status: CoverageStatus): string | null {
  if (status === CoverageStatus.NO_POINT) {
    return NO_POINT_IN_REACH;
  }
  return null;
}

/** La dirección que guarda el pedido: el punto, no la casa del paciente. */
export function pointAddress(point: {
  name: string;
  municipality: string;
}): string {
  return `${point.name}, ${point.municipality}`.slice(0, 160);
}
