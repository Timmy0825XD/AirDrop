import { BadRequestException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import {
  FleetSnapshot,
  KPI_TARGETS,
  Kpi,
  KpiGroup,
  OrderFact,
  PERIOD_INVERTED,
  PERIOD_TOO_LONG,
  PeriodFacts,
  ZONE_MIN_ORDERS,
  buildDemand,
  buildHubRanking,
  buildKpis,
  kpiStatus,
  previousPeriod,
  resolvePeriod,
  zoneCell,
} from './analytics.rules';

const HUB_A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const minutes = (value: number) => value * 60_000;

const period = resolvePeriod('2026-10-01', '2026-10-10', '2026-10-28');
// Mediodía del 5 de octubre en Colombia.
const base = new Date('2026-10-05T17:00:00.000Z');
const after = (value: number) => new Date(base.getTime() + minutes(value));
const now = new Date('2026-10-28T17:00:00.000Z');

function fact(overrides: Partial<OrderFact> = {}): OrderFact {
  return {
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    status: OrderStatus.DELIVERED,
    medicationName: 'Acetaminofén 500 mg',
    quantity: 1,
    originHubId: HUB_A,
    destinationHubId: null,
    latitude: 10.4631,
    longitude: -73.2532,
    createdAt: base,
    authorizedAt: after(4),
    loadConfirmedAt: after(8),
    deliveredAt: after(20),
    flightStartedAt: after(8),
    landedAt: after(15),
    returnedAt: after(25),
    codeLocked: false,
    coldChainAlert: false,
    batteryIncident: false,
    fallbackKind: null,
    reassigned: false,
    kmFlown: 10,
    ...overrides,
  };
}

function facts(orders: OrderFact[], quarantinedUnits = 0): PeriodFacts {
  return { period, orders, quarantinedUnits };
}

const snapshot: FleetSnapshot = {
  drones: [
    { hubId: HUB_A, status: DroneStatus.AVAILABLE },
    { hubId: HUB_B, status: DroneStatus.MAINTENANCE },
  ],
  activeHubIds: [HUB_A, HUB_B],
  expiringUnits: 12,
};

function find(groups: KpiGroup[], key: string): Kpi {
  const found = groups
    .flatMap((group) => group.kpis)
    .find((k) => k.key === key);
  if (!found) {
    throw new Error(`Falta el KPI ${key}`);
  }
  return found;
}

describe('resolvePeriod', () => {
  it('sin fechas son los últimos 30 días hasta hoy', () => {
    const resolved = resolvePeriod(undefined, undefined, '2026-10-28');
    expect(resolved.fromDate).toBe('2026-09-29');
    expect(resolved.toDate).toBe('2026-10-28');
    expect(resolved.from.toISOString()).toBe('2026-09-29T05:00:00.000Z');
    expect(resolved.to.toISOString()).toBe('2026-10-29T05:00:00.000Z');
  });

  it('rechaza un periodo al revés o de más de un año', () => {
    expect(() => resolvePeriod('2026-10-10', '2026-10-01')).toThrow(
      new BadRequestException(PERIOD_INVERTED),
    );
    expect(() => resolvePeriod('2025-01-01', '2026-10-01')).toThrow(
      new BadRequestException(PERIOD_TOO_LONG),
    );
  });

  it('el periodo anterior dura lo mismo y termina justo antes', () => {
    const before = previousPeriod(period);
    expect(before.fromDate).toBe('2026-09-21');
    expect(before.toDate).toBe('2026-09-30');
    expect(before.to.getTime()).toBe(period.from.getTime());
  });
});

describe('kpiStatus', () => {
  it('pinta el borde de cada meta', () => {
    const delivery = KPI_TARGETS.emergencyDeliveryMinutes;
    expect(kpiStatus(30, delivery)).toBe('green');
    expect(kpiStatus(30.1, delivery)).toBe('amber');
    expect(kpiStatus(45, delivery)).toBe('amber');
    expect(kpiStatus(45.1, delivery)).toBe('red');
    const success = KPI_TARGETS.successRate;
    expect(kpiStatus(90, success)).toBe('green');
    expect(kpiStatus(89.9, success)).toBe('amber');
    expect(kpiStatus(74.9, success)).toBe('red');
    const usage = KPI_TARGETS.fleetUtilization;
    expect(kpiStatus(30, usage)).toBe('green');
    expect(kpiStatus(80, usage)).toBe('green');
    expect(kpiStatus(85, usage)).toBe('amber');
    expect(kpiStatus(10, usage)).toBe('red');
  });

  it('sin dato o sin meta no hay semáforo', () => {
    expect(kpiStatus(null, KPI_TARGETS.successRate)).toBe('none');
    expect(kpiStatus(12, null)).toBe('none');
  });
});

describe('buildKpis', () => {
  it('calcula resultados, fallas y deficiencias del periodo', () => {
    const groups = buildKpis(
      facts(
        [
          fact(),
          fact({
            status: OrderStatus.RETURNED,
            deliveredAt: null,
            coldChainAlert: true,
            codeLocked: true,
          }),
          fact({
            status: OrderStatus.REJECTED,
            authorizedAt: null,
            loadConfirmedAt: null,
            deliveredAt: null,
            flightStartedAt: null,
            landedAt: null,
            returnedAt: null,
            kmFlown: 0,
          }),
          fact({
            missionType: MissionType.SCHEDULED,
            status: OrderStatus.REASSIGNED,
            fallbackKind: FallbackKind.CONVENTIONAL,
            reassigned: true,
            authorizedAt: null,
            loadConfirmedAt: null,
            deliveredAt: null,
            flightStartedAt: null,
            landedAt: null,
            returnedAt: null,
            kmFlown: 0,
          }),
        ],
        3,
      ),
      facts([fact(), fact()]),
      snapshot,
      now,
    );
    expect(groups.map((group) => group.key)).toEqual([
      'results',
      'opportunities',
      'failures',
      'deficiencies',
    ]);
    expect(find(groups, 'missions')).toMatchObject({
      value: 2,
      previous: 2,
      delta: 0,
    });
    expect(find(groups, 'successRate')).toMatchObject({
      value: 50,
      previous: 100,
      delta: -50,
      status: 'red',
    });
    expect(find(groups, 'emergencyDeliveryMinutes')).toMatchObject({
      value: 20,
      status: 'green',
    });
    expect(find(groups, 'emergencyResponseMinutes').value).toBe(4);
    expect(find(groups, 'unmetDemandRate').value).toBe(50);
    expect(find(groups, 'returnRate').value).toBe(50);
    expect(find(groups, 'coldChainAlerts').value).toBe(1);
    expect(find(groups, 'quarantinedUnits')).toMatchObject({
      value: 3,
      previous: 0,
      status: 'amber',
    });
    expect(find(groups, 'lockedCodes').value).toBe(1);
    expect(find(groups, 'reassignmentRate').value).toBe(25);
    expect(find(groups, 'kmFlown').value).toBe(20);
    expect(find(groups, 'hubsWithoutDrone')).toMatchObject({
      value: 1,
      previous: null,
      delta: null,
      status: 'amber',
    });
    expect(find(groups, 'dronesInMaintenance').value).toBe(1);
    expect(find(groups, 'expiringUnits').value).toBe(12);
  });

  it('una urgencia autorizada después de 5 min, o aún recibida, esperó demasiado', () => {
    const groups = buildKpis(
      facts([
        fact({ authorizedAt: after(6) }),
        fact({
          status: OrderStatus.RECEIVED,
          authorizedAt: null,
          loadConfirmedAt: null,
          deliveredAt: null,
        }),
        fact({ authorizedAt: after(3) }),
      ]),
      facts([]),
      snapshot,
      now,
    );
    expect(find(groups, 'unattendedEmergencies')).toMatchObject({
      value: 2,
      status: 'amber',
    });
  });

  it('el uso de la flota es el tiempo en misión sobre el tiempo disponible', () => {
    // Un dron en servicio, 10 días: 24 h de misión son el 10 %.
    const groups = buildKpis(
      facts([fact({ flightStartedAt: base, returnedAt: after(24 * 60) })]),
      facts([]),
      {
        ...snapshot,
        drones: [{ hubId: HUB_A, status: DroneStatus.AVAILABLE }],
      },
      now,
    );
    expect(find(groups, 'fleetUtilization')).toMatchObject({
      value: 10,
      status: 'red',
    });
  });

  it('sin pedidos no inventa porcentajes', () => {
    const groups = buildKpis(facts([]), facts([]), snapshot, now);
    expect(find(groups, 'successRate')).toMatchObject({
      value: null,
      status: 'none',
    });
    expect(find(groups, 'missions').value).toBe(0);
  });
});

describe('buildDemand', () => {
  const names = new Map([[HUB_B, 'Clínica Norte']]);

  it('ordena los medicamentos más pedidos y cuenta los que no se atendieron', () => {
    const demand = buildDemand(
      [
        fact({ medicationName: 'Insulina NPH', quantity: 2 }),
        fact({ medicationName: 'insulina nph ', status: OrderStatus.REJECTED }),
        fact(),
      ],
      names,
    );
    expect(demand.topMedications[0]).toEqual({
      name: 'Insulina NPH',
      orders: 2,
      units: 3,
      unmet: 1,
    });
  });

  it('muestra solo celdas con al menos 3 pedidos y nunca la coordenada exacta', () => {
    const nearby = Array.from({ length: ZONE_MIN_ORDERS }, () => fact());
    const lonely = fact({ latitude: 10.6, longitude: -73.1 });
    const demand = buildDemand([...nearby, lonely], names);
    expect(demand.zones.cells).toEqual([
      { ...zoneCell(10.4631, -73.2532), orders: ZONE_MIN_ORDERS },
    ]);
    expect(demand.zones.hiddenOrders).toBe(1);
    const serialized = JSON.stringify(demand);
    expect(serialized).not.toContain('10.4631');
    expect(serialized).not.toContain('requester');
  });

  it('los traslados cuentan por central de destino, no por coordenada', () => {
    const demand = buildDemand(
      [
        fact({
          destinationKind: DestinationKind.HUB,
          destinationHubId: HUB_B,
        }),
      ],
      names,
    );
    expect(demand.byDestinationHub).toEqual([
      { hubId: HUB_B, name: 'Clínica Norte', orders: 1 },
    ]);
    expect(demand.zones.cells).toEqual([]);
  });

  it('agrupa por día de Colombia y por tipo de misión', () => {
    const demand = buildDemand(
      [fact(), fact({ missionType: MissionType.SCHEDULED })],
      names,
    );
    expect(demand.byDay).toEqual([
      { date: '2026-10-05', emergency: 1, scheduled: 1 },
    ]);
    expect(demand.byMissionType).toEqual({ emergency: 1, scheduled: 1 });
  });
});

describe('buildHubRanking', () => {
  it('ordena las centrales por misiones y suma sus drones', () => {
    const ranking = buildHubRanking(
      facts([fact(), fact(), fact({ originHubId: HUB_B })]),
      snapshot,
      new Map([
        [HUB_A, 'Hospital Rosario'],
        [HUB_B, 'Clínica Norte'],
      ]),
      now,
    );
    expect(ranking.map((row) => [row.name, row.missions])).toEqual([
      ['Hospital Rosario', 2],
      ['Clínica Norte', 1],
    ]);
    expect(ranking[0]).toMatchObject({ availableDrones: 1, totalDrones: 1 });
    expect(ranking[1]).toMatchObject({ availableDrones: 0, totalDrones: 1 });
  });
});
