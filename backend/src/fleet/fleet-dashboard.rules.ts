import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import {
  Period,
  ZONE_MIN_ORDERS,
  zoneCell,
} from '../analytics/analytics.rules';
import { NO_CORRIDOR } from '../decision/decision.rules';
import { NO_CORRIDOR_NOTE } from '../decision/decision-trace.rules';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DecisionTrace } from '../orders/order.entity';
import { todayInColombia } from '../orders/orders.rules';
import { DESTINATION_IN_GEOFENCE } from '../routing/routing.rules';
import {
  isMaintenanceDue,
  isMaintenanceOverdue,
  maintenanceCycles,
} from './maintenance.rules';

/**
 * CU-20 para el operador: solo lo que sirve para cuidar la flota. Uso,
 * salud, incidentes y zonas de vuelo, en agregados. No nombra medicamentos
 * ni personas, y una zona sale solo con 3 vuelos o más (como `/analytics`).
 */

export type DashboardDrone = {
  id: string;
  identifier: string;
  hubId: string;
  status: DroneStatus;
  batteryPercent: number;
  flightsSinceMaintenance: number;
  maintenanceUntil: string | null;
  createdAt: Date;
};

export type DashboardFlight = {
  droneId: string;
  startedAt: Date;
  /** `null` mientras sigue en el aire. */
  returnedAt: Date | null;
  km: number;
  /** Batería al volver a la central; `null` en vuelos de antes de medirla. */
  landingBatteryPercent: number | null;
  batteryAlert: boolean;
  failureAlert: boolean;
  coldChainAlert: boolean;
  /** Volvió con el paquete (código vencido, bloqueado o traslado rechazado). */
  returnedWithPackage: boolean;
  /** Punto de entrega; solo cuenta en zonas de 3 vuelos o más. */
  latitude: number | null;
  longitude: number | null;
};

export type DashboardPeriod = {
  droneId: string;
  kind: DroneMaintenanceKind;
  startedAt: Date;
  closedAt: Date | null;
};

/** Un destino que se quedó sin corredor por una geovalla. */
export type GeofenceBlock = {
  latitude: number | null;
  longitude: number | null;
};

/**
 * ¿Una geovalla dejó sin corredor a una de estas centrales? Sale de la traza
 * del motor: la central sin corredor, un dron descartado por eso, o el
 * destino rechazado por caer dentro de una geovalla.
 */
export function blockedByGeofence(
  order: {
    status: OrderStatus;
    statusReason: string | null;
    originHubId: string | null;
    decisionTrace: DecisionTrace | null;
  },
  hubIds: string[],
): boolean {
  const mine = (hubId: string | null) =>
    hubId != null && hubIds.includes(hubId);
  const hubs = order.decisionTrace?.hubs ?? [];
  if (
    order.status === OrderStatus.REJECTED &&
    order.statusReason === DESTINATION_IN_GEOFENCE
  ) {
    return mine(order.originHubId) || hubs.some((hub) => mine(hub.hubId));
  }
  return hubs.some(
    (hub) =>
      mine(hub.hubId) &&
      (hub.note === NO_CORRIDOR_NOTE ||
        hub.drones.some((drone) => drone.reason === NO_CORRIDOR)),
  );
}

export type DashboardFacts = {
  period: Period;
  now: Date;
  drones: DashboardDrone[];
  flights: DashboardFlight[];
  maintenance: DashboardPeriod[];
  geofenceBlocks: GeofenceBlock[];
};

export function buildFleetDashboard(facts: DashboardFacts) {
  const { period, now } = facts;
  const today = todayInColombia(now);
  const cycles = maintenanceCycles();
  const periodEnd = Math.min(period.to.getTime(), now.getTime());
  const flightsBy = groupBy(facts.flights, (flight) => flight.droneId);
  const shopBy = groupBy(facts.maintenance, (row) => row.droneId);

  const usage = facts.drones.map((drone) => {
    const flights = flightsBy.get(drone.id) ?? [];
    // Un dron que nació a mitad del periodo solo cuenta desde su alta.
    const start = Math.max(period.from.getTime(), drone.createdAt.getTime());
    const span = Math.max(0, periodEnd - start);
    const inMission = sumOverlap(
      flights.map((flight) => [flight.startedAt, flight.returnedAt]),
      start,
      periodEnd,
      now,
    );
    const inShop = sumOverlap(
      (shopBy.get(drone.id) ?? []).map((row) => [row.startedAt, row.closedAt]),
      start,
      periodEnd,
      now,
    );
    return {
      droneId: drone.id,
      identifier: drone.identifier,
      hubId: drone.hubId,
      flights: flights.length,
      km: round(flights.reduce((sum, flight) => sum + flight.km, 0)),
      inMissionPercent: share(inMission, span),
      inShopPercent: share(inShop, span),
      availablePercent: span
        ? round(Math.max(0, 100 - share(inMission, span) - share(inShop, span)))
        : 0,
      spanMs: span,
      inMissionMs: inMission,
      inShopMs: inShop,
    };
  });
  const totalSpan = usage.reduce((sum, row) => sum + row.spanMs, 0);
  const totalMission = usage.reduce((sum, row) => sum + row.inMissionMs, 0);
  const totalShop = usage.reduce((sum, row) => sum + row.inShopMs, 0);

  const landings = facts.flights
    .map((flight) => flight.landingBatteryPercent)
    .filter((value): value is number => value != null);

  const health = facts.drones.map((drone) => ({
    droneId: drone.id,
    identifier: drone.identifier,
    hubId: drone.hubId,
    status: drone.status,
    batteryPercent: drone.batteryPercent,
    flightsSinceMaintenance: drone.flightsSinceMaintenance,
    maintenanceCycles: cycles,
    maintenanceDue: isMaintenanceDue(drone.flightsSinceMaintenance, cycles),
    maintenanceOverdue: isMaintenanceOverdue(drone, today),
    landingBattery: summarize(
      (flightsBy.get(drone.id) ?? [])
        .map((flight) => flight.landingBatteryPercent)
        .filter((value): value is number => value != null),
    ),
  }));

  return {
    period: { from: period.fromDate, to: period.toDate },
    usage: {
      flights: facts.flights.length,
      km: round(facts.flights.reduce((sum, flight) => sum + flight.km, 0)),
      inMissionPercent: share(totalMission, totalSpan),
      inShopPercent: share(totalShop, totalSpan),
      availablePercent: totalSpan
        ? round(
            Math.max(
              0,
              100 -
                share(totalMission, totalSpan) -
                share(totalShop, totalSpan),
            ),
          )
        : 0,
      byDrone: usage.map((row) => ({
        droneId: row.droneId,
        identifier: row.identifier,
        hubId: row.hubId,
        flights: row.flights,
        km: row.km,
        inMissionPercent: row.inMissionPercent,
        inShopPercent: row.inShopPercent,
        availablePercent: row.availablePercent,
      })),
    },
    health: {
      landingBattery: summarize(landings),
      maintenanceDue: health.filter((row) => row.maintenanceDue).length,
      maintenanceOverdue: health.filter((row) => row.maintenanceOverdue).length,
      byDrone: health,
    },
    incidents: buildIncidents(facts),
    zones: {
      flights: cells(facts.flights),
      geofenceBlocks: {
        total: facts.geofenceBlocks.length,
        zones: cells(facts.geofenceBlocks),
      },
    },
  };
}

function buildIncidents(facts: DashboardFacts) {
  const count = (flights: DashboardFlight[]) => ({
    battery: flights.filter((flight) => flight.batteryAlert).length,
    failure: flights.filter((flight) => flight.failureAlert).length,
    coldChain: flights.filter((flight) => flight.coldChainAlert).length,
    returnedWithPackage: flights.filter((flight) => flight.returnedWithPackage)
      .length,
  });
  const byDrone = groupBy(facts.flights, (flight) => flight.droneId);
  const byDay = groupBy(facts.flights, (flight) =>
    todayInColombia(flight.startedAt),
  );
  return {
    ...count(facts.flights),
    byDrone: facts.drones
      .map((drone) => ({
        droneId: drone.id,
        identifier: drone.identifier,
        ...count(byDrone.get(drone.id) ?? []),
      }))
      .filter(
        (row) =>
          row.battery + row.failure + row.coldChain + row.returnedWithPackage >
          0,
      ),
    byDay: [...byDay.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([date, flights]) => ({
        date,
        flights: flights.length,
        ...count(flights),
      })),
  };
}

/** Celdas de ~1 km con al menos 3 puntos, de la más concurrida a la menos. */
function cells(
  points: Array<{ latitude: number | null; longitude: number | null }>,
) {
  const counts = new Map<
    string,
    { latitude: number; longitude: number; count: number }
  >();
  for (const point of points) {
    if (point.latitude == null || point.longitude == null) {
      continue;
    }
    const cell = zoneCell(point.latitude, point.longitude);
    const key = `${cell.latitude},${cell.longitude}`;
    const row = counts.get(key) ?? { ...cell, count: 0 };
    row.count += 1;
    counts.set(key, row);
  }
  return [...counts.values()]
    .filter((row) => row.count >= ZONE_MIN_ORDERS)
    .sort((a, b) => b.count - a.count)
    .map((row) => ({
      latitude: row.latitude,
      longitude: row.longitude,
      count: row.count,
    }));
}

/** Milisegundos de los tramos `[inicio, fin]` dentro de `[from, to]`. */
function sumOverlap(
  spans: Array<[Date, Date | null]>,
  from: number,
  to: number,
  now: Date,
): number {
  let total = 0;
  for (const [start, end] of spans) {
    const a = Math.max(start.getTime(), from);
    const b = Math.min((end ?? now).getTime(), to);
    total += Math.max(0, b - a);
  }
  return total;
}

function summarize(values: number[]) {
  if (!values.length) {
    return { average: null, min: null, samples: 0 };
  }
  return {
    average: round(
      values.reduce((sum, value) => sum + value, 0) / values.length,
    ),
    min: round(Math.min(...values)),
    samples: values.length,
  };
}

function share(part: number, total: number): number {
  return total > 0 ? round(Math.min(100, (part / total) * 100)) : 0;
}

function groupBy<T>(rows: T[], key: (row: T) => string): Map<string, T[]> {
  const groups = new Map<string, T[]>();
  for (const row of rows) {
    const id = key(row);
    groups.set(id, [...(groups.get(id) ?? []), row]);
  }
  return groups;
}

function round(value: number, digits = 1): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}
