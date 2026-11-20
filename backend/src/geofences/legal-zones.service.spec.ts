import { ConflictException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { RolesGuard } from '../auth/roles.guard';
import { ROLES_KEY } from '../auth/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { ChangeReasonDto, CreateLegalZoneDto } from './dto/legal-zone.dto';
import { diffGeofence } from './geofence-change.rules';
import { GeofenceRow, toPublicGeofence } from './geofence.presenter';
import { GeofencesController } from './geofences.controller';
import {
  LEGAL_ALREADY_INACTIVE,
  LEGAL_ZONE_NOT_FOUND,
  LegalZonesService,
} from './legal-zones.service';
import { LegalZonesController } from './legal-zones.controller';

const admin = { id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' } as User;
const ZONE_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

const square = {
  type: 'Polygon',
  coordinates: [
    [
      [-73.25, 10.46],
      [-73.24, 10.46],
      [-73.24, 10.47],
      [-73.25, 10.46],
    ],
  ],
};

function zoneRow(overrides: Partial<GeofenceRow> = {}): GeofenceRow {
  return {
    id: ZONE_ID,
    class: 'prohibited' as GeofenceRow['class'],
    shape: 'circle' as GeofenceRow['shape'],
    name: 'CAI Hurtado',
    reason: null,
    category: null,
    centerLatitude: '10.503800',
    centerLongitude: '-73.268200',
    radiusM: 100,
    polygon: JSON.stringify(square),
    code: 'cai-hurtado',
    legalBasis: 'RAC 100.315(a)(13)',
    source: 'Lista del equipo',
    active: true,
    createdByUserId: null,
    updatedByUserId: null,
    createdAt: new Date('2026-11-20T10:00:00Z'),
    updatedAt: new Date('2026-11-20T10:00:00Z'),
    expiresAt: null,
    ...overrides,
  };
}

function build(current: GeofenceRow[]) {
  const writes: Array<[string, unknown[]]> = [];
  const manager = {
    query: jest.fn((sql: string, params: unknown[]) => {
      writes.push([sql, params]);
      if (sql.startsWith('UPDATE')) {
        return Promise.resolve([
          [
            zoneRow({
              active: params[1] as boolean,
              updatedByUserId: admin.id,
            }),
          ],
          1,
        ]);
      }
      return Promise.resolve([]);
    }),
  };
  const geofences = {
    query: jest.fn().mockResolvedValue(current),
    manager: {
      transaction: jest.fn((work: (m: typeof manager) => unknown) =>
        work(manager),
      ),
    },
  };
  const changes = { find: jest.fn().mockResolvedValue([]) };
  const operational = {
    assertCoversNoHub: jest.fn().mockResolvedValue(undefined),
    recheckFlights: jest.fn().mockResolvedValue(undefined),
  };
  const airspace = { reload: jest.fn().mockResolvedValue(undefined) };
  const service = new LegalZonesService(
    geofences as never,
    changes as never,
    operational as never,
    airspace as never,
  );
  return { service, writes, airspace, operational };
}

describe('Zonas legales del administrador (RU-36, CU-52)', () => {
  it('desactivar guarda el motivo en el historial y recarga el espacio aéreo', async () => {
    const { service, writes, airspace, operational } = build([zoneRow()]);
    const zone = await service.deactivate(admin, ZONE_ID, 'Cerró el CAI');
    expect(zone.active).toBe(false);
    const history = writes.find(([sql]) =>
      sql.includes('INSERT INTO geofence_changes'),
    );
    expect(history?.[1].slice(0, 4)).toEqual([
      ZONE_ID,
      admin.id,
      'deactivated',
      'Cerró el CAI',
    ]);
    expect(JSON.parse(String(history?.[1][4]))).toEqual({
      active: { from: true, to: false },
    });
    expect(airspace.reload).toHaveBeenCalledTimes(1);
    expect(operational.recheckFlights).toHaveBeenCalledTimes(1);
  });

  it('desactivar una que ya está desactivada responde 409', async () => {
    const { service } = build([zoneRow({ active: false })]);
    await expect(service.deactivate(admin, ZONE_ID, 'x')).rejects.toThrow(
      new ConflictException(LEGAL_ALREADY_INACTIVE),
    );
  });

  it('reactivar revisa que no cubra una central', async () => {
    const { service, operational } = build([zoneRow({ active: false })]);
    await service.reactivate(admin, ZONE_ID, 'La Policía la reabrió');
    expect(operational.assertCoversNoHub).toHaveBeenCalledTimes(1);
  });

  it('una geovalla que no es legal no se toca por aquí', async () => {
    const { service } = build([]);
    await expect(service.deactivate(admin, ZONE_ID, 'x')).rejects.toThrow(
      new NotFoundException(LEGAL_ZONE_NOT_FOUND),
    );
  });

  it('el historial solo cuenta lo que cambió', () => {
    const before = toPublicGeofence(zoneRow());
    const after = toPublicGeofence(zoneRow({ name: 'CAI Hurtado Norte' }));
    expect(diffGeofence(before, after)).toEqual({
      name: { from: 'CAI Hurtado', to: 'CAI Hurtado Norte' },
    });
  });
});

describe('Datos de una zona legal', () => {
  const body = {
    code: 'cai-nuevo',
    class: 'prohibited',
    name: 'CAI Nuevo',
    legalBasis: 'RAC 100.315(a)(13)',
    source: 'Policía Nacional',
    shape: 'circle',
    center: { latitude: 10.47, longitude: -73.25 },
    radiusM: 100,
  };

  async function errors(dto: new () => object, data: object) {
    const failures = await validate(plainToInstance(dto, data));
    return failures.flatMap((f) => Object.values(f.constraints ?? {}));
  }

  it('sin base legal o sin fuente no se guarda', async () => {
    expect(
      await errors(CreateLegalZoneDto, { ...body, legalBasis: '' }),
    ).toContain('La base legal es obligatoria.');
    expect(
      await errors(CreateLegalZoneDto, { ...body, source: ' ' }),
    ).toContain('La fuente es obligatoria.');
  });

  it('una operativa o temporal no es una clase legal', async () => {
    expect(
      await errors(CreateLegalZoneDto, { ...body, class: 'operational' }),
    ).toContain('La clase debe ser aeródromo, prohibida o helipuerto.');
  });

  it('el código va en minúsculas y guiones', async () => {
    expect(await errors(CreateLegalZoneDto, body)).toEqual([]);
    expect(
      await errors(CreateLegalZoneDto, { ...body, code: 'CAI Nuevo' }),
    ).toContain('El código va en minúsculas, números y guiones (cai-hurtado).');
  });

  it('desactivar sin motivo no se acepta', async () => {
    expect(await errors(ChangeReasonDto, { reason: '  ' })).toContain(
      'El motivo del cambio es obligatorio.',
    );
  });
});

describe('Permisos por rol', () => {
  const roles = (target: object, method?: string) =>
    Reflect.getMetadata(
      ROLES_KEY,
      method
        ? (target as Record<string, object>)[method]
        : (target as { constructor: object }).constructor,
    ) as UserRole[] | undefined;

  it('las zonas legales son solo del admin', () => {
    expect(
      Reflect.getMetadata(ROLES_KEY, LegalZonesController) as UserRole[],
    ).toEqual([UserRole.ADMIN]);
  });

  it('el operador y el admin ven; solo el operador crea, edita y borra operativas', () => {
    const proto = GeofencesController.prototype;
    expect(
      Reflect.getMetadata(ROLES_KEY, GeofencesController) as UserRole[],
    ).toEqual([UserRole.FLEET_OPERATOR, UserRole.ADMIN]);
    for (const method of ['create', 'update', 'remove']) {
      expect(roles(proto, method)).toEqual([UserRole.FLEET_OPERATOR]);
    }
    expect(roles(proto, 'catalog')).toBeUndefined();
    expect(RolesGuard).toBeDefined();
  });
});
