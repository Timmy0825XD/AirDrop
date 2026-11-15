import { BadRequestException, ConflictException } from '@nestjs/common';
import { AirspaceService } from '../airspace/airspace.service';
import { ESES, NODES } from '../airspace/regional-network';
import { HubNetworkRole } from '../common/enums/hub-network-role.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { Hub } from './hub.entity';
import { HubsService } from './hubs.service';
import { assertNodeOrigin } from './hubs.rules';

/** RF-06 y RF-43: dónde puede quedar cada tipo de central. */
const admin = { id: 'admin-1', role: UserRole.ADMIN } as User;

function dtoAt(
  role: HubNetworkRole,
  point: { latitude: number; longitude: number },
): CreateHubDto {
  return {
    name: 'Central de prueba',
    type: HubType.PHARMACY,
    networkRole: role,
    address: 'Dirección de prueba',
    latitude: point.latitude,
    longitude: point.longitude,
    contactPhone: '3001234567',
  };
}

function build(existing?: Partial<Hub>, hasDrones = false) {
  const hubs = {
    create: jest.fn((value: Partial<Hub>) => value),
    save: jest.fn((value: Partial<Hub>) =>
      Promise.resolve({ id: 'hub-1', ...value }),
    ),
    findOne: jest
      .fn()
      .mockResolvedValue(existing ? { id: 'hub-1', ...existing } : null),
    manager: { exists: jest.fn().mockResolvedValue(hasDrones) },
  };
  return {
    service: new HubsService(hubs as never, new AirspaceService()),
    hubs,
  };
}

describe('Tipo de red de la central (RF-06)', () => {
  it('crea un nodo fuera de toda zona', async () => {
    const { service } = build();
    const created = await service.create(
      admin,
      dtoAt(HubNetworkRole.NODE, NODES.north),
    );
    expect(created.networkRole).toBe(HubNetworkRole.NODE);
  });

  it('no crea un nodo en la ciudad de Valledupar (anillo del aeropuerto)', async () => {
    const { service, hubs } = build();
    await expect(
      service.create(
        admin,
        dtoAt(HubNetworkRole.NODE, { latitude: 10.47, longitude: -73.25 }),
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(hubs.save).not.toHaveBeenCalled();
  });

  it('no crea un nodo junto a una estación de policía (zona coordinada)', async () => {
    const { service } = build();
    await expect(
      service.create(admin, dtoAt(HubNetworkRole.NODE, ESES.sanDiego)),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('sí crea la ESE de San Diego dentro de la zona coordinada de su estación', async () => {
    const { service } = build();
    const created = await service.create(
      admin,
      dtoAt(HubNetworkRole.ESE, ESES.sanDiego),
    );
    expect(created.networkRole).toBe(HubNetworkRole.ESE);
  });

  it('una ESE tampoco va en zona prohibida', async () => {
    const { service } = build();
    await expect(
      service.create(
        admin,
        dtoAt(HubNetworkRole.ESE, { latitude: 10.47, longitude: -73.25 }),
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('un nodo con drones no pasa a ESE', async () => {
    const { service } = build(
      {
        networkRole: HubNetworkRole.NODE,
        latitude: NODES.south.latitude,
        longitude: NODES.south.longitude,
      },
      true,
    );
    await expect(
      service.update(admin, 'hub-1', { networkRole: HubNetworkRole.ESE }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('una ESE no es origen de un vuelo; un nodo o una fila de antes sí', () => {
    expect(() => assertNodeOrigin({ networkRole: HubNetworkRole.ESE })).toThrow(
      BadRequestException,
    );
    expect(() =>
      assertNodeOrigin({ networkRole: HubNetworkRole.NODE }),
    ).not.toThrow();
    expect(() => assertNodeOrigin({})).not.toThrow();
  });
});
