import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { RegisterMaintenanceDto } from './dto/register-maintenance.dto';
import { UpdateDroneStatusDto } from './dto/update-drone-status.dto';
import { ESTIMATED_END_NOT_PAST } from './dto/is-today-or-later.validator';

/** 2026-11-05 a las 23:30 en Colombia (ya es 6 de noviembre en UTC). */
const FIXED_NOW = new Date('2026-11-06T04:30:00.000Z');

async function errors<T extends object>(
  dto: new () => T,
  data: object,
): Promise<string[]> {
  const failures = await validate(plainToInstance(dto, data));
  return failures.flatMap((failure) =>
    Object.values(failure.constraints ?? {}),
  );
}

describe('Validación del mantenimiento', () => {
  beforeAll(() => {
    jest.useFakeTimers({ now: FIXED_NOW });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  const maintenance = (overrides: object = {}) => ({
    reason: 'Cambio de hélices',
    estimatedEndDate: '2026-11-10',
    ...overrides,
  });

  it('acepta un motivo y una fecha futura', async () => {
    expect(await errors(RegisterMaintenanceDto, maintenance())).toEqual([]);
  });

  it('acepta terminar hoy, con el día de Colombia y no el de UTC', async () => {
    const body = maintenance({ estimatedEndDate: '2026-11-05' });
    expect(await errors(RegisterMaintenanceDto, body)).toEqual([]);
  });

  it('rechaza una fecha pasada', async () => {
    const body = maintenance({ estimatedEndDate: '2026-11-04' });
    expect(await errors(RegisterMaintenanceDto, body)).toContain(
      ESTIMATED_END_NOT_PAST,
    );
  });

  it.each(['2026-02-31', '2026-13-01', '2026-11-00'])(
    'rechaza %s, que no existe, con 400 y no con 500',
    async (estimatedEndDate) => {
      const body = maintenance({ estimatedEndDate });
      expect(await errors(RegisterMaintenanceDto, body)).toContain(
        'La fecha estimada no es una fecha válida.',
      );
    },
  );

  it('rechaza un motivo de solo espacios', async () => {
    expect(
      await errors(RegisterMaintenanceDto, maintenance({ reason: '   ' })),
    ).toContain('El motivo es obligatorio.');
  });

  it('guarda el motivo sin los espacios de los bordes', () => {
    const dto = plainToInstance(
      RegisterMaintenanceDto,
      maintenance({ reason: '  Cambio de hélices  ' }),
    );
    expect(dto.reason).toBe('Cambio de hélices');
  });

  it('el cambio de estado aplica las mismas reglas a la fecha', async () => {
    const past = await errors(UpdateDroneStatusDto, {
      status: DroneStatus.MAINTENANCE,
      estimatedEndDate: '2026-11-01',
    });
    const impossible = await errors(UpdateDroneStatusDto, {
      status: DroneStatus.MAINTENANCE,
      estimatedEndDate: '2026-02-30',
    });
    expect(past).toContain(ESTIMATED_END_NOT_PAST);
    expect(impossible).toContain('La fecha estimada no es una fecha válida.');
  });

  it('el cambio de estado sigue aceptando venir sin fecha', async () => {
    expect(
      await errors(UpdateDroneStatusDto, { status: DroneStatus.AVAILABLE }),
    ).toEqual([]);
  });
});
