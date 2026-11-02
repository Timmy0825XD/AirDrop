/**
 * Geometría plana del planificador (RF-12 y RF-21). Las coordenadas se
 * proyectan a kilómetros alrededor de la misión: a la escala de Valledupar
 * (menos de 40 km) el error frente a la esfera es despreciable.
 *
 * Idea para el tablero: el camino más corto que esquiva polígonos convexos
 * pasa por sus esquinas. Se infla cada geovalla con el margen, se toman sus
 * esquinas como nodos y Dijkstra une la central con el destino.
 */

/** Punto en el plano local, en kilómetros. */
export type PlanePoint = { x: number; y: number };

/** Lado de una zona: un punto del lado y su normal unitaria hacia adentro. */
type ZoneEdge = { x: number; y: number; nx: number; ny: number };

/** Geovalla inflada: polígono convexo en sentido antihorario. */
export type Zone = {
  hull: PlanePoint[];
  edges: ZoneEdge[];
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
};

/** Tolerancia de 1 m: tocar el borde de una zona no es entrar en ella. */
const EDGE_TOLERANCE_KM = 0.001;

/** El margen se dibuja como un octágono que contiene el círculo del radio. */
const OCTAGON_SIDES = 8;

const KM_PER_DEGREE = (6371 * Math.PI) / 180;

/** Proyección equirectangular centrada en la misión. */
export type Projection = {
  toPlane(longitude: number, latitude: number): PlanePoint;
  toLngLat(point: PlanePoint): [number, number];
};

export function projectionAround(
  longitude: number,
  latitude: number,
): Projection {
  const kmPerLng = KM_PER_DEGREE * Math.cos((latitude * Math.PI) / 180);
  return {
    toPlane: (lng, lat) => ({
      x: (lng - longitude) * kmPerLng,
      y: (lat - latitude) * KM_PER_DEGREE,
    }),
    toLngLat: (point) => [
      roundTo(point.x / kmPerLng + longitude, 6),
      roundTo(point.y / KM_PER_DEGREE + latitude, 6),
    ],
  };
}

/**
 * La geovalla más su margen: cada vértice se rodea con un octágono del radio
 * y se toma la cáscara convexa. Con una geovalla cóncava rodea de más, nunca
 * de menos.
 */
export function inflateRing(ring: PlanePoint[], marginKm: number): Zone {
  const radius = marginKm / Math.cos(Math.PI / OCTAGON_SIDES);
  const points: PlanePoint[] = [];
  for (const vertex of ring) {
    for (let side = 0; side < OCTAGON_SIDES; side += 1) {
      const angle = (Math.PI / OCTAGON_SIDES) * (2 * side + 1);
      points.push({
        x: vertex.x + radius * Math.cos(angle),
        y: vertex.y + radius * Math.sin(angle),
      });
    }
  }
  const hull = convexHull(points);
  const edges: ZoneEdge[] = [];
  hull.forEach((a, index) => {
    const b = hull[(index + 1) % hull.length];
    const length = Math.hypot(b.x - a.x, b.y - a.y);
    if (length > 0) {
      edges.push({
        x: a.x,
        y: a.y,
        nx: -(b.y - a.y) / length,
        ny: (b.x - a.x) / length,
      });
    }
  });
  return {
    hull,
    edges,
    minX: Math.min(...hull.map((point) => point.x)),
    maxX: Math.max(...hull.map((point) => point.x)),
    minY: Math.min(...hull.map((point) => point.y)),
    maxY: Math.max(...hull.map((point) => point.y)),
  };
}

/** Cáscara convexa (cadena monótona), antihoraria y sin puntos colineales. */
export function convexHull(points: PlanePoint[]): PlanePoint[] {
  const sorted = [...points].sort((a, b) => a.x - b.x || a.y - b.y);
  if (sorted.length < 3) {
    return sorted;
  }
  const lower: PlanePoint[] = [];
  for (const point of sorted) {
    while (
      lower.length >= 2 &&
      cross(lower[lower.length - 2], lower[lower.length - 1], point) <= 0
    ) {
      lower.pop();
    }
    lower.push(point);
  }
  const upper: PlanePoint[] = [];
  for (let index = sorted.length - 1; index >= 0; index -= 1) {
    const point = sorted[index];
    while (
      upper.length >= 2 &&
      cross(upper[upper.length - 2], upper[upper.length - 1], point) <= 0
    ) {
      upper.pop();
    }
    upper.push(point);
  }
  lower.pop();
  upper.pop();
  return lower.concat(upper);
}

/** ¿El punto está dentro de la zona, a más de 1 m del borde? */
export function isInsideZone(point: PlanePoint, zone: Zone): boolean {
  return segmentEntersZone(point, point, zone);
}

/**
 * ¿El segmento pasa por el interior de la zona? Recorta el segmento contra
 * cada lado del polígono convexo (Cyrus-Beck). Rozar un vértice o correr por
 * el borde no cuenta: así los nodos del grafo, que están en el borde, quedan
 * conectados.
 */
export function segmentEntersZone(
  start: PlanePoint,
  end: PlanePoint,
  zone: Zone,
): boolean {
  if (
    Math.max(start.x, end.x) < zone.minX ||
    Math.min(start.x, end.x) > zone.maxX ||
    Math.max(start.y, end.y) < zone.minY ||
    Math.min(start.y, end.y) > zone.maxY
  ) {
    return false;
  }
  let enter = 0;
  let exit = 1;
  for (const edge of zone.edges) {
    // Profundidad con signo hacia adentro en t = 0, y cuánto cambia hasta t = 1.
    const startDepth =
      (start.x - edge.x) * edge.nx + (start.y - edge.y) * edge.ny;
    const rate = (end.x - start.x) * edge.nx + (end.y - start.y) * edge.ny;
    if (rate === 0) {
      if (startDepth <= EDGE_TOLERANCE_KM) {
        return false;
      }
      continue;
    }
    const t = (EDGE_TOLERANCE_KM - startDepth) / rate;
    if (rate > 0) {
      enter = Math.max(enter, t);
    } else {
      exit = Math.min(exit, t);
    }
    if (enter > exit) {
      return false;
    }
  }
  return exit >= enter;
}

/**
 * Dijkstra sobre el grafo de visibilidad, guiado hacia la meta (A*): explora
 * primero los nodos que, en línea recta, prometen llegar antes. La línea recta
 * nunca es más larga que el camino real, así que el resultado sigue siendo el
 * más corto. `blocked(i, j)` dice si el tramo cruza algo y se pregunta solo
 * cuando hace falta. Devuelve los índices del camino, o `null` si no hay.
 */
export function shortestVisiblePath(
  nodes: PlanePoint[],
  start: number,
  goal: number,
  blocked: (from: number, to: number) => boolean,
): number[] | null {
  const distance = nodes.map(() => Infinity);
  const previous: Array<number | null> = nodes.map(() => null);
  const done = nodes.map(() => false);
  const toGoal = nodes.map((node) => planeDistance(node, nodes[goal]));
  distance[start] = 0;
  for (;;) {
    let current = -1;
    for (let index = 0; index < nodes.length; index += 1) {
      if (
        !done[index] &&
        distance[index] < Infinity &&
        (current === -1 ||
          distance[index] + toGoal[index] < distance[current] + toGoal[current])
      ) {
        current = index;
      }
    }
    if (current === -1) {
      return null;
    }
    if (current === goal) {
      break;
    }
    done[current] = true;
    for (let next = 0; next < nodes.length; next += 1) {
      if (done[next] || next === current) {
        continue;
      }
      const candidate =
        distance[current] + planeDistance(nodes[current], nodes[next]);
      if (candidate >= distance[next] || blocked(current, next)) {
        continue;
      }
      distance[next] = candidate;
      previous[next] = current;
    }
  }
  const path: number[] = [];
  for (let at: number | null = goal; at != null; at = previous[at]) {
    path.unshift(at);
  }
  return path;
}

function planeDistance(a: PlanePoint, b: PlanePoint): number {
  return Math.hypot(b.x - a.x, b.y - a.y);
}

/** Positivo si `point` queda a la izquierda de origin → end. */
function cross(origin: PlanePoint, end: PlanePoint, point: PlanePoint): number {
  return (
    (end.x - origin.x) * (point.y - origin.y) -
    (end.y - origin.y) * (point.x - origin.x)
  );
}

function roundTo(value: number, digits: number): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}
