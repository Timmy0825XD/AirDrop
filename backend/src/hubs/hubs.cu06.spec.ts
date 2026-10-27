/**
 * Pruebas unitarias del CU-06 (Crear central), casos CP-06-01 a CP-06-08 de
 * la Segunda Parte. El nombre de cada `it` empieza con el ID del caso para que
 * la terminal lo muestre en la captura.
 */
import { ForbiddenException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { Hub } from './hub.entity';
import { HubsService } from './hubs.service';

const valido: CreateHubDto = {
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4631,
  longitude: -73.2532,
  contactPhone: '3001234567',
  contactEmail: 'contacto@rosario.co',
};

function usuario(overrides: Partial<User> = {}): User {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    role: UserRole.ADMIN,
    status: UserStatus.ACTIVE,
    ...overrides,
  } as User;
}

function build() {
  const guardadas: Hub[] = [];
  const hubs = {
    create: jest.fn((value: Partial<Hub>) => value),
    save: jest.fn((value: Hub) => {
      const hub = {
        ...value,
        id: '22222222-2222-4222-8222-222222222222',
        createdAt: new Date('2026-10-26T15:00:00.000Z'),
      };
      guardadas.push(hub);
      return Promise.resolve(hub);
    }),
  };
  return { service: new HubsService(hubs as never), hubs, guardadas };
}

async function errores(data: object): Promise<string[]> {
  const fallos = await validate(plainToInstance(CreateHubDto, data));
  return fallos.flatMap((fallo) => Object.values(fallo.constraints ?? {}));
}

describe('CU-06 Crear central', () => {
  it('CP-06-01 crea una central con todos los datos válidos y queda activa', async () => {
    expect(await errores(valido)).toEqual([]);
    const { service, guardadas } = build();

    const central = await service.create(usuario(), valido);

    expect(central.status).toBe(HubStatus.ACTIVE);
    expect(central.name).toBe('Hospital Rosario Pumarejo');
    expect(central.contactEmail).toBe('contacto@rosario.co');
    expect(guardadas).toHaveLength(1);
  });

  it('CP-06-02 crea una central sin correo de contacto (opcional)', async () => {
    const sinCorreo = {
      ...valido,
      name: 'Farmacia Central',
      type: HubType.PHARMACY,
      address: 'Carrera 9 No. 15-20, Valledupar',
      latitude: 10.47,
      longitude: -73.25,
      contactPhone: '3109876543',
      contactEmail: undefined,
    };
    expect(await errores(sinCorreo)).toEqual([]);
    const { service } = build();

    const central = await service.create(usuario(), sinCorreo);

    expect(central.contactEmail).toBeNull();
    expect(central.status).toBe(HubStatus.ACTIVE);
  });

  it('CP-06-03 rechaza un tipo de central no admitido (400)', async () => {
    expect(await errores({ ...valido, type: 'laboratorio' })).toContain(
      'El tipo de central no es válido.',
    );
  });

  it('CP-06-04 rechaza el nombre vacío (400)', async () => {
    expect(await errores({ ...valido, name: '' })).toContain(
      'El nombre es obligatorio.',
    );
  });

  it('CP-06-05 rechaza la latitud 90.000001 y acepta el límite 90 (400)', async () => {
    expect(await errores({ ...valido, latitude: 90.000001 })).toContain(
      'La latitud no es válida.',
    );
    expect(await errores({ ...valido, latitude: 90 })).toEqual([]);
  });

  it('CP-06-06 rechaza un celular de 9 dígitos y acepta uno de 10 (400)', async () => {
    expect(await errores({ ...valido, contactPhone: '300123456' })).toContain(
      'El celular debe tener exactamente 10 dígitos (Colombia).',
    );
    expect(await errores({ ...valido, contactPhone: '3001234567' })).toEqual(
      [],
    );
  });

  it('CP-06-07 rechaza la creación por un usuario que no es administrador (403)', async () => {
    const { service, hubs } = build();

    const intento = service.create(
      usuario({ role: UserRole.DISPATCHER }),
      valido,
    );

    await expect(intento).rejects.toBeInstanceOf(ForbiddenException);
    await expect(intento).rejects.toThrow(
      'Solo el administrador crea centrales.',
    );
    expect(hubs.save).not.toHaveBeenCalled();
  });

  it('CP-06-08 rechaza la creación por un administrador con la cuenta no activa (403)', async () => {
    const { service, hubs } = build();

    const intento = service.create(
      usuario({ status: UserStatus.SUSPENDED }),
      valido,
    );

    await expect(intento).rejects.toBeInstanceOf(ForbiddenException);
    await expect(intento).rejects.toThrow(
      'Tu cuenta debe estar activa para gestionar la central.',
    );
    expect(hubs.save).not.toHaveBeenCalled();
  });
});
