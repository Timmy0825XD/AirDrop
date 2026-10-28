import { BadRequestException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import {
  UNATTENDED_EMERGENCY_MS,
  addCalendarDays,
  todayInColombia,
} from '../orders/orders.rules';

/** Sin fechas, el tablero mira los últimos 30 días. */
export const DEFAULT_PERIOD_DAYS = 30;
export const MAX_PERIOD_DAYS = 366;
/** Stock que vence pronto. */
export const EXPIRING_SOON_DAYS = 30;
/** Celdas de ~1 km; una celda con menos pedidos no se muestra (anonimato). */
export const ZONE_CELL_DEGREES = 0.01;
export const ZONE_MIN_ORDERS = 3;
export const TOP_MEDICATIONS = 10;

export const PERIOD_INVERTED =
  'La fecha inicial no puede ser posterior a la final.';
export const PERIOD_TOO_LONG = `El periodo no puede superar ${MAX_PERIOD_DAYS} días.`;

const MINUTE_MS = 60_000;
const DAY_MS = 24 * 60 * MINUTE_MS;

export type Period = {
  fromDate: string;
  toDate: string;
  /** Inicio del primer día en Colombia. */
  from: Date;
  /** Inicio del día siguiente al último (exclusivo). */
  to: Date;
};

export type KpiStatus = 'green' | 'amber' | 'red' | 'none';

/**
 * Meta de un KPI. `max`: mejor si es bajo; `min`: mejor si es alto; `band`:
 * sano entre `min` y `max`. `amber` es el borde tolerable antes del rojo.
 */
export type KpiTarget =
  | { kind: 'max'; green: number; amber: number }
  | { kind: 'min'; green: number; amber: number }
  | {
      kind: 'band';
      min: number;
      max: number;
      amberMin: number;
      amberMax: number;
    };

export type Kpi = {
  key: string;
  label: string;
  value: number | null;
  unit: string;
  target: KpiTarget | null;
  status: KpiStatus;
  previous: number | null;
  delta: number | null;
};

export type KpiGroup = { key: string; label: string; kpis: Kpi[] };

/** Lo que el tablero sabe de cada pedido. Nada identifica a una persona. */
export type OrderFact = {
  missionType: MissionType;
  destinationKind: DestinationKind;
  status: OrderStatus;
  medicationName: string;
  quantity: number;
  originHubId: string | null;
  destinationHubId: string | null;
  latitude: number | null;
  longitude: number | null;
  createdAt: Date;
  authorizedAt: Date | null;
  loadConfirmedAt: Date | null;
  deliveredAt: Date | null;
  flightStartedAt: Date | null;
  landedAt: Date | null;
  returnedAt: Date | null;
  codeLocked: boolean;
  coldChainAlert: boolean;
  batteryIncident: boolean;
  fallbackKind: FallbackKind | null;
  reassigned: boolean;
  kmFlown: number;
};

export type PeriodFacts = {
  period: Period;
  orders: OrderFact[];
  quarantinedUnits: number;
};

export type FleetSnapshot = {
  drones: Array<{ hubId: string; status: DroneStatus }>;
  activeHubIds: string[];
  expiringUnits: number;
};

/** Metas del tablero del administrador (RF-26). */
export const KPI_TARGETS = {
  successRate: { kind: 'min', green: 90, amber: 75 },
  emergencyDeliveryMinutes: { kind: 'max', green: 30, amber: 45 },
  emergencyResponseMinutes: { kind: 'max', green: 10, amber: 15 },
  unmetDemandRate: { kind: 'max', green: 5, amber: 10 },
  unattendedEmergencies: { kind: 'max', green: 0, amber: 2 },
  returnRate: { kind: 'max', green: 5, amber: 10 },
  coldChainAlerts: { kind: 'max', green: 0, amber: 1 },
  quarantinedUnits: { kind: 'max', green: 0, amber: 5 },
  batteryIncidents: { kind: 'max', green: 0, amber: 1 },
  lockedCodes: { kind: 'max', green: 0, amber: 2 },
  reassignmentRate: { kind: 'max', green: 10, amber: 20 },
  fleetUtilization: {
    kind: 'band',
    min: 30,
    max: 80,
    amberMin: 15,
    amberMax: 90,
  },
  hubsWithoutDrone: { kind: 'max', green: 0, amber: 1 },
} satisfies Record<string, KpiTarget>;

/** Fechas `YYYY-MM-DD` de Colombia; sin ellas, los últimos 30 días. */
export function resolvePeriod(
  fromDate: string | undefined,
  toDate: string | undefined,
  today = todayInColombia(),
): Period {
  const to = toDate ?? today;
  const from = fromDate ?? addCalendarDays(to, -(DEFAULT_PERIOD_DAYS - 1));
  if (from > to) {
    throw new BadRequestException(PERIOD_INVERTED);
  }
  const period = toPeriod(from, to);
  if (period.to.getTime() - period.from.getTime() > MAX_PERIOD_DAYS * DAY_MS) {
    throw new BadRequestException(PERIOD_TOO_LONG);
  }
  return period;
}

/** El periodo anterior dura lo mismo y termina justo antes. */
export function previousPeriod(period: Period): Period {
  const days = Math.round(
    (period.to.getTime() - period.from.getTime()) / DAY_MS,
  );
  const toDate = addCalendarDays(period.fromDate, -1);
  return toPeriod(addCalendarDays(toDate, -(days - 1)), toDate);
}

function toPeriod(fromDate: string, toDate: string): Period {
  return {
    fromDate,
    toDate,
    from: colombiaMidnight(fromDate),
    to: colombiaMidnight(addCalendarDays(toDate, 1)),
  };
}

/** Colombia no tiene horario de verano: siempre UTC−5. */
function colombiaMidnight(date: string): Date {
  return new Date(`${date}T00:00:00-05:00`);
}

export function kpiStatus(
  value: number | null,
  target: KpiTarget | null,
): KpiStatus {
  if (value == null || target == null) {
    return 'none';
  }
  if (target.kind === 'max') {
    if (value <= target.green) return 'green';
    return value <= target.amber ? 'amber' : 'red';
  }
  if (target.kind === 'min') {
    if (value >= target.green) return 'green';
    return value >= target.amber ? 'amber' : 'red';
  }
  if (value >= target.min && value <= target.max) return 'green';
  return value >= target.amberMin && value <= target.amberMax ? 'amber' : 'red';
}

function kpi(
  key: string,
  label: string,
  unit: string,
  value: number | null,
  previous: number | null,
  target: KpiTarget | null = null,
): Kpi {
  return {
    key,
    label,
    value,
    unit,
    target,
    status: kpiStatus(value, target),
    previous,
    delta: value != null && previous != null ? round(value - previous) : null,
  };
}

/** Métricas que se comparan entre periodos. */
type PeriodMeasures = {
  missions: number;
  unitsDelivered: number;
  kmFlown: number;
  successRate: number | null;
  emergencyDeliveryMinutes: number | null;
  emergencyResponseMinutes: number | null;
  loadMinutes: number | null;
  flightMinutes: number | null;
  unmetDemandRate: number | null;
  unattendedEmergencies: number;
  returnRate: number | null;
  coldChainAlerts: number;
  quarantinedUnits: number;
  batteryIncidents: number;
  lockedCodes: number;
  reassignmentRate: number | null;
  fleetUtilization: number | null;
};

export function measurePeriod(
  facts: PeriodFacts,
  fleetSize: number,
  now = new Date(),
): PeriodMeasures {
  const orders = facts.orders;
  const requested = orders.filter(
    (order) => order.status !== OrderStatus.CANCELLED,
  );
  const delivered = orders.filter(
    (order) => order.status === OrderStatus.DELIVERED,
  );
  const returned = orders.filter(
    (order) => order.status === OrderStatus.RETURNED,
  );
  const closed = delivered.length + returned.length;
  const emergencies = orders.filter(
    (order) => order.missionType === MissionType.EMERGENCY,
  );
  const unmet = orders.filter(
    (order) =>
      order.status === OrderStatus.REJECTED ||
      (order.status === OrderStatus.REASSIGNED &&
        order.fallbackKind === FallbackKind.CONVENTIONAL),
  );
  return {
    missions: orders.filter((order) => order.loadConfirmedAt).length,
    unitsDelivered: delivered.reduce((sum, order) => sum + order.quantity, 0),
    kmFlown: round(orders.reduce((sum, order) => sum + order.kmFlown, 0)),
    successRate: percent(delivered.length, closed),
    emergencyDeliveryMinutes: averageMinutes(
      emergencies.map((order) => span(order.createdAt, order.deliveredAt)),
    ),
    emergencyResponseMinutes: averageMinutes(
      emergencies.map((order) => span(order.createdAt, order.authorizedAt)),
    ),
    loadMinutes: averageMinutes(
      orders.map((order) => span(order.authorizedAt, order.loadConfirmedAt)),
    ),
    flightMinutes: averageMinutes(
      orders.map((order) => span(order.flightStartedAt, order.landedAt)),
    ),
    unmetDemandRate: percent(unmet.length, requested.length),
    unattendedEmergencies: emergencies.filter((order) =>
      waitedTooLong(order, facts.period, now),
    ).length,
    returnRate: percent(returned.length, closed),
    coldChainAlerts: orders.filter((order) => order.coldChainAlert).length,
    quarantinedUnits: facts.quarantinedUnits,
    batteryIncidents: orders.filter((order) => order.batteryIncident).length,
    lockedCodes: orders.filter((order) => order.codeLocked).length,
    reassignmentRate: percent(
      orders.filter((order) => order.reassigned).length,
      requested.length,
    ),
    fleetUtilization: fleetUtilization(orders, fleetSize, facts.period, now),
  };
}

/**
 * KPI del administrador: resultados, oportunidades, fallas y deficiencias,
 * con meta, semáforo y comparación con el periodo anterior.
 */
export function buildKpis(
  current: PeriodFacts,
  previous: PeriodFacts,
  snapshot: FleetSnapshot,
  now = new Date(),
): KpiGroup[] {
  const fleetSize = snapshot.drones.filter(
    (drone) => drone.status !== DroneStatus.OUT_OF_SERVICE,
  ).length;
  const measured = measurePeriod(current, fleetSize, now);
  const before = measurePeriod(previous, fleetSize, now);
  const hubsWithoutDrone = snapshot.activeHubIds.filter(
    (hubId) =>
      !snapshot.drones.some(
        (drone) =>
          drone.hubId === hubId && drone.status === DroneStatus.AVAILABLE,
      ),
  ).length;
  const t = KPI_TARGETS;
  return [
    {
      key: 'results',
      label: 'Resultados',
      kpis: [
        kpi(
          'missions',
          'Misiones',
          'misiones',
          measured.missions,
          before.missions,
        ),
        kpi(
          'successRate',
          'Entregas exitosas',
          '%',
          measured.successRate,
          before.successRate,
          t.successRate,
        ),
        kpi(
          'emergencyDeliveryMinutes',
          'Urgencia: de pedida a entregada',
          'min',
          measured.emergencyDeliveryMinutes,
          before.emergencyDeliveryMinutes,
          t.emergencyDeliveryMinutes,
        ),
        kpi(
          'emergencyResponseMinutes',
          'Urgencia: de pedida a autorizada',
          'min',
          measured.emergencyResponseMinutes,
          before.emergencyResponseMinutes,
          t.emergencyResponseMinutes,
        ),
        kpi(
          'loadMinutes',
          'De autorizada a cargada',
          'min',
          measured.loadMinutes,
          before.loadMinutes,
        ),
        kpi(
          'flightMinutes',
          'Duración media de la ida',
          'min',
          measured.flightMinutes,
          before.flightMinutes,
        ),
        kpi(
          'unitsDelivered',
          'Unidades entregadas',
          'unidades',
          measured.unitsDelivered,
          before.unitsDelivered,
        ),
        kpi(
          'kmFlown',
          'Distancia volada',
          'km',
          measured.kmFlown,
          before.kmFlown,
        ),
      ],
    },
    {
      key: 'opportunities',
      label: 'Oportunidades',
      kpis: [
        kpi(
          'unmetDemandRate',
          'Demanda sin atender (rechazos y traslado convencional)',
          '%',
          measured.unmetDemandRate,
          before.unmetDemandRate,
          t.unmetDemandRate,
        ),
        kpi(
          'unattendedEmergencies',
          'Urgencias que esperaron más de 5 min',
          'pedidos',
          measured.unattendedEmergencies,
          before.unattendedEmergencies,
          t.unattendedEmergencies,
        ),
      ],
    },
    {
      key: 'failures',
      label: 'Fallas',
      kpis: [
        kpi(
          'returnRate',
          'Retornos sin entrega',
          '%',
          measured.returnRate,
          before.returnRate,
          t.returnRate,
        ),
        kpi(
          'coldChainAlerts',
          'Alertas de frío',
          'pedidos',
          measured.coldChainAlerts,
          before.coldChainAlerts,
          t.coldChainAlerts,
        ),
        kpi(
          'quarantinedUnits',
          'Unidades en cuarentena',
          'unidades',
          measured.quarantinedUnits,
          before.quarantinedUnits,
          t.quarantinedUnits,
        ),
        kpi(
          'batteryIncidents',
          'Batería crítica o falla de dron',
          'misiones',
          measured.batteryIncidents,
          before.batteryIncidents,
          t.batteryIncidents,
        ),
        kpi(
          'lockedCodes',
          'Códigos bloqueados',
          'pedidos',
          measured.lockedCodes,
          before.lockedCodes,
          t.lockedCodes,
        ),
        kpi(
          'reassignmentRate',
          'Pedidos reasignados a otra central',
          '%',
          measured.reassignmentRate,
          before.reassignmentRate,
          t.reassignmentRate,
        ),
      ],
    },
    {
      key: 'deficiencies',
      label: 'Deficiencias',
      kpis: [
        kpi(
          'fleetUtilization',
          'Uso de la flota',
          '%',
          measured.fleetUtilization,
          before.fleetUtilization,
          t.fleetUtilization,
        ),
        kpi(
          'hubsWithoutDrone',
          'Centrales sin dron disponible',
          'centrales',
          hubsWithoutDrone,
          null,
          t.hubsWithoutDrone,
        ),
        kpi(
          'dronesInMaintenance',
          'Drones en mantenimiento',
          'drones',
          snapshot.drones.filter(
            (drone) => drone.status === DroneStatus.MAINTENANCE,
          ).length,
          null,
        ),
        kpi(
          'expiringUnits',
          `Stock que vence en ${EXPIRING_SOON_DAYS} días`,
          'unidades',
          snapshot.expiringUnits,
          null,
        ),
      ],
    },
  ];
}

/** Conteos por tipo de misión y por estado. */
export function breakdown(orders: OrderFact[]) {
  const byMissionType: Record<string, number> = {};
  const byStatus: Record<string, number> = {};
  for (const order of orders) {
    byMissionType[order.missionType] =
      (byMissionType[order.missionType] ?? 0) + 1;
    byStatus[order.status] = (byStatus[order.status] ?? 0) + 1;
  }
  return { byMissionType, byStatus };
}

/**
 * Dashboard epidemiológico: qué se pide más y desde dónde. Las personas
 * aparecen solo como celdas de ~1 km con al menos 3 pedidos.
 */
export function buildDemand(
  orders: OrderFact[],
  hubNames: Map<string, string>,
) {
  const medications = new Map<
    string,
    { name: string; orders: number; units: number; unmet: number }
  >();
  const destinations = new Map<string, number>();
  const cells = new Map<
    string,
    { latitude: number; longitude: number; orders: number }
  >();
  const days = new Map<string, { emergency: number; scheduled: number }>();
  for (const order of orders) {
    const key = order.medicationName.trim().toLowerCase();
    const medication = medications.get(key) ?? {
      name: order.medicationName.trim(),
      orders: 0,
      units: 0,
      unmet: 0,
    };
    medication.orders += 1;
    medication.units += order.quantity;
    if (isUnmet(order)) {
      medication.unmet += 1;
    }
    medications.set(key, medication);
    if (order.destinationKind === DestinationKind.HUB) {
      if (order.destinationHubId) {
        destinations.set(
          order.destinationHubId,
          (destinations.get(order.destinationHubId) ?? 0) + 1,
        );
      }
    } else if (order.latitude != null && order.longitude != null) {
      const cell = zoneCell(order.latitude, order.longitude);
      const cellKey = `${cell.latitude}|${cell.longitude}`;
      const entry = cells.get(cellKey) ?? { ...cell, orders: 0 };
      entry.orders += 1;
      cells.set(cellKey, entry);
    }
    const day = todayInColombia(order.createdAt);
    const counts = days.get(day) ?? { emergency: 0, scheduled: 0 };
    if (order.missionType === MissionType.EMERGENCY) {
      counts.emergency += 1;
    } else {
      counts.scheduled += 1;
    }
    days.set(day, counts);
  }
  const visible = [...cells.values()].filter(
    (cell) => cell.orders >= ZONE_MIN_ORDERS,
  );
  const shown = visible.reduce((sum, cell) => sum + cell.orders, 0);
  const inCells = [...cells.values()].reduce(
    (sum, cell) => sum + cell.orders,
    0,
  );
  return {
    topMedications: [...medications.values()]
      .sort(
        (left, right) =>
          right.orders - left.orders || left.name.localeCompare(right.name),
      )
      .slice(0, TOP_MEDICATIONS),
    byDestinationHub: [...destinations.entries()]
      .map(([hubId, count]) => ({
        hubId,
        name: hubNames.get(hubId) ?? null,
        orders: count,
      }))
      .sort((left, right) => right.orders - left.orders),
    zones: {
      cellDegrees: ZONE_CELL_DEGREES,
      minOrders: ZONE_MIN_ORDERS,
      cells: visible.sort((left, right) => right.orders - left.orders),
      hiddenOrders: inCells - shown,
    },
    byDay: [...days.entries()]
      .map(([date, counts]) => ({ date, ...counts }))
      .sort((left, right) => left.date.localeCompare(right.date)),
    ...breakdown(orders),
  };
}

/** Ranking por central de origen, de la que más despachó a la que menos. */
export function buildHubRanking(
  facts: PeriodFacts,
  snapshot: FleetSnapshot,
  hubNames: Map<string, string>,
  now = new Date(),
) {
  return snapshot.activeHubIds
    .map((hubId) => {
      const drones = snapshot.drones.filter((drone) => drone.hubId === hubId);
      const fleetSize = drones.filter(
        (drone) => drone.status !== DroneStatus.OUT_OF_SERVICE,
      ).length;
      const measures = measurePeriod(
        {
          ...facts,
          orders: facts.orders.filter((order) => order.originHubId === hubId),
          quarantinedUnits: 0,
        },
        fleetSize,
        now,
      );
      return {
        hubId,
        name: hubNames.get(hubId) ?? null,
        missions: measures.missions,
        successRate: measures.successRate,
        returnRate: measures.returnRate,
        emergencyDeliveryMinutes: measures.emergencyDeliveryMinutes,
        coldChainAlerts: measures.coldChainAlerts,
        fleetUtilization: measures.fleetUtilization,
        availableDrones: drones.filter(
          (drone) => drone.status === DroneStatus.AVAILABLE,
        ).length,
        totalDrones: drones.length,
      };
    })
    .sort(
      (left, right) =>
        right.missions - left.missions ||
        (left.name ?? '').localeCompare(right.name ?? ''),
    );
}

/** Centro de la celda de ~1 km donde cae un punto. */
export function zoneCell(
  latitude: number,
  longitude: number,
): { latitude: number; longitude: number } {
  const center = (value: number) =>
    round(
      Math.floor(value / ZONE_CELL_DEGREES) * ZONE_CELL_DEGREES +
        ZONE_CELL_DEGREES / 2,
      3,
    );
  return { latitude: center(latitude), longitude: center(longitude) };
}

function isUnmet(order: OrderFact): boolean {
  return (
    order.status === OrderStatus.REJECTED ||
    (order.status === OrderStatus.REASSIGNED &&
      order.fallbackKind === FallbackKind.CONVENTIONAL)
  );
}

/**
 * Una urgencia esperó demasiado si la autorizaron pasados 5 min, o si sigue
 * recibida y ya pasaron 5 min. Las rechazadas no cuentan.
 */
function waitedTooLong(order: OrderFact, period: Period, now: Date): boolean {
  if (order.authorizedAt) {
    return span(order.createdAt, order.authorizedAt)! > UNATTENDED_EMERGENCY_MS;
  }
  if (order.status !== OrderStatus.RECEIVED) {
    return false;
  }
  const until = Math.min(now.getTime(), period.to.getTime());
  return until - order.createdAt.getTime() > UNATTENDED_EMERGENCY_MS;
}

/**
 * Tiempo de los drones en misión (de despegar a volver a la central) sobre
 * el tiempo disponible de la flota en el periodo.
 */
function fleetUtilization(
  orders: OrderFact[],
  fleetSize: number,
  period: Period,
  now: Date,
): number | null {
  const periodEnd = Math.min(period.to.getTime(), now.getTime());
  const available = fleetSize * (periodEnd - period.from.getTime());
  if (available <= 0) {
    return null;
  }
  let busy = 0;
  for (const order of orders) {
    if (!order.flightStartedAt) {
      continue;
    }
    const start = Math.max(
      order.flightStartedAt.getTime(),
      period.from.getTime(),
    );
    const end = Math.min((order.returnedAt ?? now).getTime(), periodEnd);
    busy += Math.max(0, end - start);
  }
  return round(Math.min(100, (busy / available) * 100));
}

function span(start: Date | null, end: Date | null): number | null {
  if (!start || !end) {
    return null;
  }
  return end.getTime() - start.getTime();
}

function averageMinutes(spans: Array<number | null>): number | null {
  const values = spans.filter(
    (value): value is number => value != null && value >= 0,
  );
  if (!values.length) {
    return null;
  }
  return round(
    values.reduce((sum, value) => sum + value, 0) / values.length / MINUTE_MS,
  );
}

function percent(part: number, total: number): number | null {
  return total > 0 ? round((part / total) * 100) : null;
}

function round(value: number, digits = 1): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}
