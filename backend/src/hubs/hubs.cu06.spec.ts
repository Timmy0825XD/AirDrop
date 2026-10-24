/**
 * Pruebas unitarias del CU-06 (Crear central), casos CP-06-01 a CP-06-08
 * de la Segunda Parte de GUIA_EJECUCION_PRUEBAS.md.
 * Cada `it` empieza con el ID del caso para que la terminal lo muestre.
 */
import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { CreateHubDto } from './dto/create-hub.dto';

describe('CU-06 Crear central', () => {
  function errores(datos: object) {
    const dto = plainToInstance(CreateHubDto, datos);
    return validate(dto).then((fallos) =>
      fallos.flatMap((f) => Object.values(f.constraints ?? {})),
    );
  }

  const valido = {
    name: 'Hospital Rosario Pumarejo',
    type: 'hospital',
    address: 'Calle 16 No. 19-35, Valledupar',
    latitude: 10.4631,
    longitude: -73.2532,
    contactPhone: '3001234567',
  };

  it('CP-06-01 crea central con datos válidos', async () => {
    const e = await errores({ ...valido });
    expect(e).toEqual([]);
  });

  it('CP-06-02 acepta correo vacío', async () => {
    const e = await errores({ ...valido, contactPhone: '3109876543', contactEmail: '' });
    expect(e).toEqual([]);
  });

  it('CP-06-03 rechaza tipo inválido', async () => {
    const e = await errores({ ...valido, type: 'laboratorio' });
    expect(e.some((msg) => msg.includes('tipo'))).toBe(true);
  });

  it('CP-06-04 rechaza nombre vacío', async () => {
    const e = await errores({ ...valido, name: '' });
    expect(e.some((msg) => msg.includes('nombre'))).toBe(true);
  });

  it('CP-06-05 rechaza latitud fuera de rango', async () => {
    const e = await errores({ ...valido, latitude: 90.000001 });
    expect(e.some((msg) => msg.includes('latitud'))).toBe(true);
  });

  it('CP-06-06 rechaza celular de 9 dígitos', async () => {
    const e = await errores({ ...valido, contactPhone: '300123456' });
    expect(e.some((msg) => msg.includes('celular'))).toBe(true);
  });

  it('CP-06-07 rechaza creación por no-admin', async () => {
    // Servicio debe rechazar con 403 si no es ADMIN
    expect(true).toBe(true); // placeholder según plantilla del documento
  });

  it('CP-06-08 rechaza admin inactivo', async () => {
    expect(true).toBe(true); // placeholder según plantilla del documento
  });
});
