import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AirspaceService } from '../airspace/airspace.service';
import { DELIVERY_POINTS } from '../airspace/regional-network';
import { HubStatus } from '../common/enums/hub-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { DeliveryPoint } from './delivery-point.entity';
import {
  CoverageStatus,
  DELIVERY_POINT_NOT_FOUND,
  DELIVERY_POINT_UNAVAILABLE,
  NO_POINT_IN_REACH,
  URBAN_NOT_SERVED,
  pointAddress,
} from './delivery-points.rules';
import { DeliveryPointsService } from './delivery-points.service';

const NORTH_HUB = 'hub-north';
const WEST_HUB = 'hub-west';

/** Plaza Alfonso López, en el centro de Valledupar. */
const DOWNTOWN = { latitude: 10.4766, longitude: -73.2434 };
/** Cerca de Badillo, en zona rural del norte. */
const NEAR_BADILLO = { latitude: 10.63, longitude: -73.13 };

function point(
  code: string,
  overrides: Partial<DeliveryPoint> = {},
): DeliveryPoint {
  const site = DELIVERY_POINTS.find((entry) => entry.code === code)!;
  return {
    id: `id-${code}`,
    code,
    name: site.name,
    municipality: site.municipality,
    latitude: site.latitude,
    longitude: site.longitude,
    elevationM: site.elevationM,
    hubId: site.nodeCode === 'node-west' ? WEST_HUB : NORTH_HUB,
    active: true,
    coordinatedZoneCode: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function build(
  rows: DeliveryPoint[],
  hubs: Array<{ id: string; status: HubStatus }> = [
    { id: NORTH_HUB, status: HubStatus.ACTIVE },
    { id: WEST_HUB, status: HubStatus.ACTIVE },
  ],
) {
  const points = {
    find: jest.fn().mockResolvedValue(rows),
    findOne: jest.fn(({ where }: { where: { id: string } }) =>
      Promise.resolve(rows.find((row) => row.id === where.id) ?? null),
    ),
    save: jest.fn((value: DeliveryPoint) => Promise.resolve(value)),
  };
  const hubRepo = {
    find: jest.fn().mockResolvedValue(
      hubs.map((hub) => ({
        ...hub,
        name: hub.id,
        address: `Dirección ${hub.id}`,
        contactPhone: '3001234567',
        contactEmail: null,
        latitude: 10.6,
        longitude: -73.2,
      })),
    ),
  };
  const query = {
    innerJoin: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    getRawMany: jest.fn().mockResolvedValue([{ hubId: NORTH_HUB }]),
  };
  const items = { createQueryBuilder: jest.fn(() => query) };
  const service = new DeliveryPointsService(
    points as never,
    hubRepo as never,
    items as never,
    new AirspaceService(),
  );
  return { service, points };
}

const requester = { role: UserRole.REQUESTER } as User;
const admin = { role: UserRole.ADMIN } as User;

describe('DeliveryPointsService (RF-45, RU-02)', () => {
  it('propone el punto activo más cercano al GPS y ordena la lista por distancia', async () => {
    const { service } = build([
      point('dp-mariangola'),
      point('dp-patillal'),
      point('dp-badillo'),
    ]);
    const result = await service.coverage(requester, NEAR_BADILLO);
    expect(result.coverage).toBe(CoverageStatus.COVERED);
    expect(result.message).toBeNull();
    expect(result.nearestPointId).toBe('id-dp-badillo');
    expect(result.points.map((row) => row.code)).toEqual([
      'dp-badillo',
      'dp-patillal',
      'dp-mariangola',
    ]);
    expect(result.points[0].distanceKm).toBeLessThan(1);
  });

  it('en la ciudad no propone punto: dice por qué y da la alternativa terrestre', async () => {
    const { service } = build([point('dp-badillo')]);
    const result = await service.coverage(requester, {
      ...DOWNTOWN,
      medicationName: 'Acetaminofén 500 mg',
    });
    expect(result.coverage).toBe(CoverageStatus.URBAN);
    expect(result.message).toBe(URBAN_NOT_SERVED);
    expect(result.nearestPointId).toBeNull();
    expect(result.alternatives[0].contactPhone).toBe('3001234567');
    expect(typeof result.alternatives[0].distanceKm).toBe('number');
  });

  it('un punto inactivo o con su nodo suspendido no se ofrece; sin ninguno, no hay cobertura', async () => {
    const { service } = build(
      [point('dp-badillo', { active: false }), point('dp-mariangola')],
      [
        { id: NORTH_HUB, status: HubStatus.ACTIVE },
        { id: WEST_HUB, status: HubStatus.SUSPENDED },
      ],
    );
    const result = await service.coverage(requester, NEAR_BADILLO);
    expect(result.coverage).toBe(CoverageStatus.NO_POINT);
    expect(result.message).toBe(NO_POINT_IN_REACH);
    expect(result.points).toEqual([]);
  });

  it('el administrador ve también los inactivos, marcados', async () => {
    const { service } = build([
      point('dp-badillo', { active: false }),
      point('dp-patillal'),
    ]);
    const result = await service.coverage(admin, {});
    expect(result.points.map((row) => [row.code, row.available])).toEqual([
      ['dp-badillo', false],
      ['dp-patillal', true],
    ]);
  });

  it('un pedido no va a un punto inactivo, inexistente, ni desde la ciudad', async () => {
    const { service } = build([point('dp-badillo', { active: false })]);
    await expect(service.requireForOrder('id-dp-badillo')).rejects.toThrow(
      new BadRequestException(DELIVERY_POINT_UNAVAILABLE),
    );
    await expect(service.requireForOrder('otro')).rejects.toThrow(
      new NotFoundException(DELIVERY_POINT_NOT_FOUND),
    );
    await expect(
      service.requireForOrder('id-dp-badillo', DOWNTOWN),
    ).rejects.toThrow(new BadRequestException(URBAN_NOT_SERVED));
  });

  it('un punto en zona coordinada dice cuál es su corredor pactado', () => {
    const { service } = build([]);
    const view = service.present(
      point('dp-atanquez', { coordinatedZoneCode: 'resguardo-kankuamo' }),
    );
    expect(view.corridor).toMatchObject({
      zoneCode: 'resguardo-kankuamo',
      gateway: { latitude: 10.655, longitude: -73.33 },
    });
  });

  it('el pedido guarda el punto como dirección', () => {
    expect(pointAddress(point('dp-badillo'))).toBe(
      'Puesto de salud de Badillo, Valledupar',
    );
  });
});
