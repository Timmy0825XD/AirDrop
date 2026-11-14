import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { HubNetworkRole } from '../../common/enums/hub-network-role.enum';
import { HubType } from '../../common/enums/hub-type.enum';
import { CreateHubDto } from './create-hub.dto';

const valid = {
  name: 'PRUEBA-Hospital',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4631,
  longitude: -73.2532,
  contactPhone: '3001234567',
  networkRole: HubNetworkRole.NODE,
};

async function messagesFor(overrides: Record<string, unknown>) {
  const dto = plainToInstance(CreateHubDto, { ...valid, ...overrides });
  const errors = await validate(dto);
  return errors.flatMap((error) => Object.values(error.constraints ?? {}));
}

describe('CreateHubDto', () => {
  it('CP-06-04 acepta nombre y dirección con contenido', async () => {
    expect(await messagesFor({})).toEqual([]);
  });

  it('RF-06 exige el tipo de red: nodo o ESE', async () => {
    expect(await messagesFor({ networkRole: undefined })).toContain(
      'El tipo de red debe ser nodo o ESE.',
    );
    expect(await messagesFor({ networkRole: 'bodega' })).toContain(
      'El tipo de red debe ser nodo o ESE.',
    );
    expect(await messagesFor({ networkRole: HubNetworkRole.ESE })).toEqual([]);
  });

  it('rechaza un nombre vacío', async () => {
    expect(await messagesFor({ name: '' })).toContain(
      'El nombre es obligatorio.',
    );
  });

  it('rechaza un nombre de solo espacios', async () => {
    expect(await messagesFor({ name: '   ' })).toContain(
      'El nombre es obligatorio.',
    );
  });

  it('rechaza una dirección vacía o de solo espacios', async () => {
    expect(await messagesFor({ address: '' })).toContain(
      'La dirección es obligatoria.',
    );
    expect(await messagesFor({ address: '  ' })).toContain(
      'La dirección es obligatoria.',
    );
  });
});
