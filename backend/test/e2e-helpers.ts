import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import { App } from 'supertest/types';
import { DocumentType } from '../src/common/enums/document-type.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
import { HubType } from '../src/common/enums/hub-type.enum';

export const TEST_PASSWORD = 'Password123';

export const DRONE_VUP_01 = 'WC-198-VUP-01';
export const DRONE_VUP_02 = 'WC-198-VUP-02';
export const DRONE_VUP_03 = 'WC-198-VUP-03';

export const anaPerez = {
  fullName: 'Ana Pérez',
  email: 'ana.perez@gmail.com',
  phone: '3001112233',
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1065487321',
};

export const marianaCastro = {
  fullName: 'Mariana Castro',
  email: 'mariana.castro@gmail.com',
  phone: '3012223344',
  documentType: DocumentType.FOREIGNER_ID,
  documentNumber: '384921',
};

export const camilaDiaz = {
  fullName: 'Camila Díaz',
  email: 'camila.diaz@gmail.com',
  phone: '3103334455',
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1065987123',
};

export const lauraGomez = {
  fullName: 'Laura Gómez',
  email: 'laura.gomez@outlook.com',
  phone: '3204445566',
};

export const julianRojas = {
  fullName: 'Julián Rojas',
  email: 'julian.rojas@yahoo.com',
  phone: '3155556677',
};

export const dianaHerrera = {
  fullName: 'Diana Herrera',
  email: 'diana.herrera@hotmail.com',
  phone: '3116667788',
};

export const santiagoMora = {
  fullName: 'Santiago Mora',
  email: 'santiago.mora@outlook.com',
  phone: '3127778899',
};

export const andresLopez = {
  fullName: 'Andrés López',
  email: 'andres.lopez@icloud.com',
  phone: '3138889900',
  documentType: DocumentType.PPT,
  documentNumber: 'PPT26A18421',
};

const people = [
  anaPerez,
  marianaCastro,
  camilaDiaz,
  lauraGomez,
  julianRojas,
  dianaHerrera,
  santiagoMora,
  andresLopez,
];

export const hubPayload = {
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.46314,
  longitude: -73.25322,
  contactPhone: '3001234567',
  contactEmail: 'urgencias@hospitalrosario.com',
};

export const clinicPayload = {
  name: 'Clínica Laura Daniela',
  type: HubType.CLINIC,
  address: 'Carrera 19 No. 16-40, Valledupar',
  latitude: 10.4742,
  longitude: -73.2598,
  contactPhone: '3007654321',
  contactEmail: 'contacto@clinicalauradaniela.com',
};

export const valleduparPolygon = {
  type: 'Polygon' as const,
  coordinates: [
    [
      [-73.26, 10.46],
      [-73.24, 10.46],
      [-73.24, 10.48],
      [-73.26, 10.48],
      [-73.26, 10.46],
    ],
  ],
};

export async function removeFixtures(
  app: INestApplication<App>,
): Promise<void> {
  const dataSource = app.get(DataSource);
  const emails = people.map((person) => person.email);
  const phones = people.map((person) => person.phone);
  const documents = people.flatMap((person) =>
    'documentNumber' in person ? [person.documentNumber] : [],
  );
  const identifiers = [DRONE_VUP_01, DRONE_VUP_02, DRONE_VUP_03];
  await dataSource.query(`DELETE FROM drones WHERE identifier = ANY($1)`, [
    identifiers,
  ]);
  await dataSource.query(
    `DELETE FROM one_time_codes
     WHERE "userId" IN (
       SELECT id FROM users
       WHERE email = ANY($1) OR phone = ANY($2) OR "documentNumber" = ANY($3)
     )`,
    [emails, phones, documents],
  );
  await dataSource.query(
    `DELETE FROM user_hubs
     WHERE "userId" IN (
       SELECT id FROM users
       WHERE email = ANY($1) OR phone = ANY($2) OR "documentNumber" = ANY($3)
     )`,
    [emails, phones, documents],
  );
  await dataSource.query(
    `DELETE FROM users
     WHERE email = ANY($1) OR phone = ANY($2) OR "documentNumber" = ANY($3)`,
    [emails, phones, documents],
  );
}

export async function registerRequester(
  app: INestApplication<App>,
  person: typeof anaPerez,
): Promise<string> {
  const register = await request(app.getHttpServer())
    .post('/auth/register')
    .send({
      ...person,
      password: TEST_PASSWORD,
      consentAccepted: true,
    })
    .expect(201);
  const otp = (register.body as { otp: string }).otp;
  const verified = await request(app.getHttpServer())
    .post('/auth/verify-otp')
    .send({ phone: person.phone, code: otp })
    .expect(201);
  return (verified.body as { accessToken: string }).accessToken;
}

export async function createStaff(
  app: INestApplication<App>,
  adminToken: string,
  person: { fullName: string; email: string; phone: string },
  role: UserRole,
  hubIds: string[],
): Promise<{ id: string; token: string }> {
  const created = await request(app.getHttpServer())
    .post('/users')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({
      fullName: person.fullName,
      email: person.email,
      phone: person.phone,
      password: TEST_PASSWORD,
      role,
      hubIds,
    })
    .expect(201);
  const login = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email: person.email, password: TEST_PASSWORD })
    .expect(200);
  return {
    id: (created.body as { id: string }).id,
    token: (login.body as { accessToken: string }).accessToken,
  };
}

export async function loginAdmin(app: INestApplication<App>): Promise<string> {
  const login = await request(app.getHttpServer())
    .post('/auth/login')
    .send({
      email: process.env.ADMIN_EMAIL ?? 'administrador.plataforma@gmail.com',
      password: process.env.ADMIN_PASSWORD ?? 'Admin1234',
    })
    .expect(200);
  return (login.body as { accessToken: string }).accessToken;
}
