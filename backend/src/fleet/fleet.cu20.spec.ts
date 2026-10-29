/**
 * Pruebas unitarias del CU-20 (Gestionar flota), casos CP-20-01 a CP-20-10 de
 * la Segunda Parte del documento. El nombre de cada `it` empieza con el ID del
 * caso para que la terminal lo muestre en la captura.
 */
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateDroneDto } from './dto/create-drone.dto';
import { UpdateDroneStatusDto } from './dto/update-drone-status.dto';
import { Drone } from './drone.entity';
import { DroneModel } from './drone-model.entity';
import { WINGCOPTER_198_CODE } from './drone-model-seed.service';
import { FleetService } from './fleet.service';

const wingcopter: DroneModel = {
  id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  code: WINGCOPTER_198_CODE,
  name: 'Wingcopter 198',
  maxSpeedKmh: 150,
  maxPayloadKg: 6,
  maxRangeKm: 110,
};

/** Central A: PRUEBA-Hospital Rosario Pumarejo, asignada al operador. */
const rosario = { id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' } as Hub;

/** Central B: PRUEBA-Clínica del Norte, NO asignada al operador. */
const clinicaNorte = { id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' } as Hub;

function operator(overrides: Partial<User> = {}): User {
  return {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    role: UserRole.FLEET_OPERATOR,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId: rosario.id }],
    ...overrides,
  } as User;
}

function droneDto(overrides: Partial<CreateDroneDto> = {}): CreateDroneDto {
  return {
    identifier: 'WG-198-001',
    droneModelId: wingcopter.id,
    hubId: rosario.id,
    ...overrides,
  };
}

function storedDrone(overrides: Partial<Drone> = {}): Drone {
  return {
    id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
    identifier: 'WG-198-001',
    droneModelId: wingcopter.id,
    hubId: rosario.id,
    status: DroneStatus.AVAILABLE,
    maintenanceReason: null,
    maintenanceUntil: null,
    createdAt: new Date('2026-10-16T15:00:00.000Z'),
    ...overrides,
  } as Drone;
}

function build(
  opts: { existing?: Drone | null; model?: DroneModel | null } = {},
) {
  const drones = {
    findOne: jest.fn().mockResolvedValue(opts.existing ?? null),
    create: jest.fn((value: Partial<Drone>) => ({
      ...storedDrone(),
      ...value,
    })),
    save: jest.fn((value: Drone) => Promise.resolve(value)),
  };
  const models = {
    find: jest.fn().mockResolvedValue([wingcopter]),
    findOne: jest
      .fn()
      .mockResolvedValue(opts.model === undefined ? wingcopter : opts.model),
  };
  const hubsService = {
    requireActive: jest.fn((id: string) => Promise.resolve({ id } as Hub)),
  } as unknown as HubsService;
  const service = new FleetService(
    drones as never,
    models as never,
    hubsService,
  );
  return { service, drones };
}

async function errors<T extends object>(
  dto: new () => T,
  data: object,
): Promise<string[]> {
  const failures = await validate(plainToInstance(dto, data));
  return failures.flatMap((failure) =>
    Object.values(failure.constraints ?? {}),
  );
}

describe('CU-20 Gestionar flota', () => {
  it('CP-20-01 registra un Wingcopter 198 con identificador único y queda disponible', async () => {
    expect(await errors(CreateDroneDto, droneDto())).toEqual([]);
    const { service, drones } = build();

    const result = await service.createDrone(operator(), droneDto());

    expect(drones.save).toHaveBeenCalledTimes(1);
    expect(result.identifier).toBe('WG-198-001');
    expect(result.droneModelId).toBe(wingcopter.id);
    expect(result.hubId).toBe(rosario.id);
    expect(result.status).toBe(DroneStatus.AVAILABLE);
  });

  it('CP-20-02 registra un mantenimiento con motivo y fecha estimada', async () => {
    const body = {
      status: DroneStatus.MAINTENANCE,
      reason: 'Revisión de hélices',
      estimatedEndDate: '2026-10-20',
    };
    expect(await errors(UpdateDroneStatusDto, body)).toEqual([]);
    const { service, drones } = build({ existing: storedDrone() });

    const result = await service.updateStatus(
      operator(),
      storedDrone().id,
      body as UpdateDroneStatusDto,
    );

    expect(drones.save).toHaveBeenCalledTimes(1);
    expect(result.status).toBe(DroneStatus.MAINTENANCE);
    expect(result.maintenanceReason).toBe('Revisión de hélices');
    expect(result.maintenanceUntil).toBe('2026-10-20');
    // El motor de decisión solo toma drones disponibles.
    expect(result.status).not.toBe(DroneStatus.AVAILABLE);
  });

  it('CP-20-03 rechaza un identificador que ya existe (409)', async () => {
    const { service, drones } = build({ existing: storedDrone() });

    const attempt = service.createDrone(operator(), droneDto());

    await expect(attempt).rejects.toBeInstanceOf(ConflictException);
    await expect(attempt).rejects.toThrow(
      'Ya existe un dron con este identificador.',
    );
    expect(drones.save).not.toHaveBeenCalled();
  });

  it('CP-20-04 rechaza el identificador vacío (400)', async () => {
    const found = await errors(CreateDroneDto, droneDto({ identifier: '' }));

    expect(found).toContain('El identificador es obligatorio.');
  });

  it('CP-20-05 rechaza un modelo de dron que no existe (404)', async () => {
    // El modelo viaja como UUID: se usa uno válido que no está registrado.
    const unknownModel = '99999999-9999-4999-8999-999999999999';
    const body = droneDto({
      identifier: 'WG-198-010',
      droneModelId: unknownModel,
    });
    expect(await errors(CreateDroneDto, body)).toEqual([]);
    const { service, drones } = build({ model: null });

    const attempt = service.createDrone(operator(), body);

    await expect(attempt).rejects.toBeInstanceOf(NotFoundException);
    await expect(attempt).rejects.toThrow('El modelo de dron no existe.');
    expect(drones.save).not.toHaveBeenCalled();
  });

  it('CP-20-06 rechaza un estado que el operador no puede asignar (400)', async () => {
    const found = await errors(UpdateDroneStatusDto, {
      status: DroneStatus.IN_MISSION,
    });

    expect(found).toContain(
      'El estado debe ser available, maintenance o out_of_service.',
    );
  });

  it('CP-20-07 no cambia el estado de un dron en misión (409)', async () => {
    const inMission = storedDrone({
      identifier: 'WG-198-004',
      status: DroneStatus.IN_MISSION,
    });
    const { service, drones } = build({ existing: inMission });

    const attempt = service.updateStatus(operator(), inMission.id, {
      status: DroneStatus.MAINTENANCE,
      reason: 'Revisión de hélices',
    });

    await expect(attempt).rejects.toBeInstanceOf(ConflictException);
    await expect(attempt).rejects.toThrow(
      'No puedes cambiar el estado de un dron en misión.',
    );
    expect(drones.save).not.toHaveBeenCalled();
    expect(inMission.status).toBe(DroneStatus.IN_MISSION);
  });

  it('CP-20-08 rechaza el alta en una central no asignada al operador (403)', async () => {
    const { service, drones } = build();

    const attempt = service.createDrone(
      operator(),
      droneDto({ identifier: 'WG-198-011', hubId: clinicaNorte.id }),
    );

    await expect(attempt).rejects.toBeInstanceOf(ForbiddenException);
    await expect(attempt).rejects.toThrow(
      'Esa central no está asignada a tu cuenta.',
    );
    expect(drones.save).not.toHaveBeenCalled();
  });

  it('CP-20-09 rechaza el alta por un operador con la cuenta no activa (403)', async () => {
    const { service, drones } = build();

    const attempt = service.createDrone(
      operator({ status: UserStatus.SUSPENDED }),
      droneDto({ identifier: 'WG-198-012' }),
    );

    await expect(attempt).rejects.toBeInstanceOf(ForbiddenException);
    await expect(attempt).rejects.toThrow(
      'Tu cuenta debe estar activa para gestionar la flota.',
    );
    expect(drones.save).not.toHaveBeenCalled();
  });

  it('CP-20-10 rechaza un mantenimiento sin motivo (motivo de 0 caracteres)', async () => {
    const found = await errors(UpdateDroneStatusDto, {
      status: DroneStatus.MAINTENANCE,
      reason: '',
      estimatedEndDate: '2026-10-20',
    });

    expect(found.length).toBeGreaterThan(0);
  });
});
