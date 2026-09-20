import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { UserRole } from '../src/common/enums/user-role.enum';
import { HubType } from '../src/common/enums/hub-type.enum';

export const hubPayload = {
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.46314,
  longitude: -73.25322,
  contactPhone: '3001234567',
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

export async function registerVerified(
  app: INestApplication<App>,
  role: UserRole,
  email: string,
): Promise<string> {
  const password = 'secreto12';
  const register = await request(app.getHttpServer())
    .post('/auth/register')
    .send({
      fullName: 'Usuario Prueba',
      email,
      password,
      role,
      consentAccepted: true,
    })
    .expect(201);
  const otp = (register.body as { otp: string }).otp;
  const verified = await request(app.getHttpServer())
    .post('/auth/verify-otp')
    .send({ email, code: otp })
    .expect(201);
  return (verified.body as { accessToken: string }).accessToken;
}

export async function loginAdmin(
  app: INestApplication<App>,
): Promise<string> {
  const login = await request(app.getHttpServer())
    .post('/auth/login')
    .send({
      email: process.env.ADMIN_EMAIL ?? 'admin@airdrop.local',
      password: process.env.ADMIN_PASSWORD ?? 'Admin1234',
    })
    .expect(200);
  return (login.body as { accessToken: string }).accessToken;
}
