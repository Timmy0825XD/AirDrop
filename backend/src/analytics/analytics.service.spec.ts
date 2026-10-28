import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { ROLES_KEY } from '../auth/roles.decorator';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { DeliveryCode } from '../delivery/delivery-code.entity';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { QuarantineRecord } from '../inventory/quarantine-record.entity';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { AnalyticsController } from './analytics.controller';
import { Kpi } from './analytics.rules';
import { AnalyticsService } from './analytics.service';

// @nestjs/swagger se publica como ESM y Jest (CommonJS) no lo carga. Sus
// decoradores solo documentan la API, así que aquí no hacen nada.
jest.mock('@nestjs/swagger', () => ({
  ApiTags: () => () => undefined,
  ApiBearerAuth: () => () => undefined,
}));

const HUB_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const created = new Date('2026-10-05T17:00:00.000Z');

function build(orders: Partial<Order>[]) {
  const repos = new Map<unknown, { find: jest.Mock }>([
    [Order, { find: jest.fn().mockResolvedValue(orders) }],
    [
      QuarantineRecord,
      { find: jest.fn().mockResolvedValue([{ quantity: 2 }]) },
    ],
    [
      DeliveryCode,
      {
        find: jest.fn().mockResolvedValue([
          {
            orderId: ORDER_ID,
            usedAt: new Date(created.getTime() + 20 * 60_000),
            attempts: 5,
          },
        ]),
      },
    ],
    [Mission, { find: jest.fn().mockResolvedValue([]) }],
    [
      Drone,
      {
        find: jest
          .fn()
          .mockResolvedValue([
            { hubId: HUB_ID, status: DroneStatus.AVAILABLE },
          ]),
      },
    ],
    [
      Hub,
      {
        find: jest
          .fn()
          .mockResolvedValue([
            { id: HUB_ID, name: 'Hospital Rosario', status: HubStatus.ACTIVE },
          ]),
      },
    ],
  ]);
  const query = jest.fn((sql: string) =>
    Promise.resolve(
      sql.includes('mission_routes')
        ? [{ orderId: ORDER_ID, km: '7.5' }]
        : [{ units: '4' }],
    ),
  );
  const dataSource = {
    getRepository: jest.fn((entity: unknown) => repos.get(entity)),
    query,
  };
  const service = new AnalyticsService(dataSource as unknown as DataSource);
  return { service, repos, query };
}

function order(): Partial<Order> {
  return {
    id: ORDER_ID,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    status: OrderStatus.DELIVERED,
    medicationName: 'Acetaminofén 500 mg',
    quantity: 1,
    originHubId: HUB_ID,
    destinationHubId: null,
    latitude: 10.46,
    longitude: -73.25,
    createdAt: created,
    authorizedAt: new Date(created.getTime() + 3 * 60_000),
    loadConfirmedAt: new Date(created.getTime() + 6 * 60_000),
    coldChainAlertAt: null,
    fallbackKind: null,
    reassignedFromHubId: null,
  };
}

function kpi(groups: Array<{ kpis: Kpi[] }>, key: string) {
  return groups.flatMap((group) => group.kpis).find((item) => item.key === key);
}

describe('AnalyticsService', () => {
  it('arma los KPI con el código, las rutas y la cuarentena del periodo', async () => {
    const { service } = build([order()]);
    const result = await service.kpis({ from: '2026-10-01', to: '2026-10-10' });
    expect(result.period).toEqual({ from: '2026-10-01', to: '2026-10-10' });
    expect(result.previousPeriod).toEqual({
      from: '2026-09-21',
      to: '2026-09-30',
    });
    expect(kpi(result.groups, 'emergencyDeliveryMinutes')?.value).toBe(20);
    expect(kpi(result.groups, 'lockedCodes')?.value).toBe(1);
    expect(kpi(result.groups, 'kmFlown')?.value).toBe(7.5);
    expect(kpi(result.groups, 'quarantinedUnits')?.value).toBe(2);
    expect(kpi(result.groups, 'expiringUnits')?.value).toBe(4);
    expect(result.byStatus).toEqual({ delivered: 1 });
  });

  it('con central, filtra los pedidos por la central de origen', async () => {
    const { service, repos } = build([]);
    await service.kpis({ hubId: HUB_ID });
    const [options] = repos.get(Order)!.find.mock.calls[0] as [
      { where: object },
    ];
    const where = options.where;
    expect(where).toMatchObject({ originHubId: HUB_ID });
  });

  it('sin pedidos no consulta códigos, misiones ni rutas', async () => {
    const { service, repos, query } = build([]);
    await service.demand({});
    expect(repos.get(DeliveryCode)!.find).not.toHaveBeenCalled();
    expect(repos.get(Mission)!.find).not.toHaveBeenCalled();
    expect(query).not.toHaveBeenCalled();
  });

  it('el ranking nombra cada central', async () => {
    const { service } = build([order()]);
    const result = await service.hubs({});
    expect(result.hubs[0]).toMatchObject({
      hubId: HUB_ID,
      name: 'Hospital Rosario',
    });
  });
});

describe('AnalyticsController', () => {
  it('solo lo abre el administrador', () => {
    const roles = new Reflector().get<UserRole[]>(
      ROLES_KEY,
      AnalyticsController,
    );
    expect(roles).toEqual([UserRole.ADMIN]);
  });
});
