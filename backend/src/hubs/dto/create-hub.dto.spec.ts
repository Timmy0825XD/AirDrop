import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { HubType } from '../../common/enums/hub-type.enum';
import { CreateHubDto } from './create-hub.dto';

const valid = {
  name: 'PRUEBA-Hospital',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4631,
  longitude: -73.2532,
  contactPhone: '3001234567',
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
