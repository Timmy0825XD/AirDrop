import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { UserRole } from '../src/common/enums/user-role.enum';
import { HubStatus } from '../src/common/enums/hub-status.enum';
import { DroneStatus } from '../src/common/enums/drone-status.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { WINGCOPTER_198_CODE } from '../src/fleet/drone-model-seed.service';
import {
  hubPayload,
  loginAdmin,
  registerVerified,
  valleduparPolygon,
} from './e2e-helpers';

const envFile = resolve(__dirname, '..', '.env');
if (existsSync(envFile)) {
  process.loadEnvFile(envFile);
}

const describeIfDb = process.env.DATABASE_URL ? describe : describe.skip;

describeIfDb('Sprint 2 (e2e)', () => {
  let app: INestApplication<App> | undefined;

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'test-jwt-secret';
    process.env.E2E_DROP_SCHEMA = process.env.E2E_DROP_SCHEMA ?? 'false';

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    await app.init();
  }, 20_000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('aprueba central, inventario con receta, flota, geovalla y suspensión', async () => {
    const stamp = Date.now();
    const dispatcherToken = await registerVerified(
      app!,
      UserRole.DISPATCHER,
      `despacho.s2.${stamp}@hospital.co`,
    );
    const requesterToken = await registerVerified(
      app!,
      UserRole.REQUESTER,
      `solicita.s2.${stamp}@correo.co`,
    );
    const operatorEmail = `flota.s2.${stamp}@hospital.co`;
    const operatorToken = await registerVerified(
      app!,
      UserRole.FLEET_OPERATOR,
      operatorEmail,
    );
    const adminToken = await loginAdmin(app!);

    const profile = await request(app!.getHttpServer())
      .patch('/auth/me')
      .set('Authorization', `Bearer ${requesterToken}`)
      .send({ fullName: 'Ana Pérez' })
      .expect(200);
    expect((profile.body as { fullName: string }).fullName).toBe('Ana Pérez');

    const hub = await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .send(hubPayload)
      .expect(201);
    const hubId = (hub.body as { id: string }).id;

    await request(app!.getHttpServer())
      .post('/inventory')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .send({
        name: 'Paracetamol 500 mg',
        quantity: 10,
        expirationDate: '2027-03-01',
        requiresColdChain: false,
        requiresPrescription: true,
      })
      .expect(403);

    await request(app!.getHttpServer())
      .patch(`/hubs/${hubId}/decision`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: HubStatus.APPROVED })
      .expect(200);

    const item = await request(app!.getHttpServer())
      .post('/inventory')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .send({
        name: 'Paracetamol 500 mg',
        quantity: 10,
        expirationDate: '2027-03-01',
        requiresColdChain: false,
        requiresPrescription: true,
      })
      .expect(201);
    expect(item.body).toMatchObject({
      name: 'Paracetamol 500 mg',
      requiresPrescription: true,
      requiresColdChain: false,
    });

    const models = await request(app!.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operatorToken}`)
      .expect(200);
    const wingcopter = (
      models.body as Array<{ id: string; code: string }>
    ).find((row) => row.code === WINGCOPTER_198_CODE);

    const drone = await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({
        identifier: `WC-S2-${stamp}`,
        droneModelId: wingcopter!.id,
        hubId,
      })
      .expect(201);
    const droneId = (drone.body as { id: string }).id;

    await request(app!.getHttpServer())
      .patch(`/fleet/drones/${droneId}/status`)
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({ status: DroneStatus.MAINTENANCE })
      .expect(200);

    const maintained = await request(app!.getHttpServer())
      .post(`/fleet/drones/${droneId}/maintenance`)
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({
        reason: 'Revisión de hélices',
        estimatedEndDate: '2026-10-01',
      })
      .expect(201);
    expect(maintained.body).toMatchObject({
      status: DroneStatus.OUT_OF_SERVICE,
      maintenanceReason: 'Revisión de hélices',
    });

    const geofence = await request(app!.getHttpServer())
      .post('/geofences')
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({
        name: 'Plaza Alfonso López',
        reason: 'Zona restringida de prueba',
        polygon: valleduparPolygon,
      })
      .expect(201);
    expect((geofence.body as { polygon: { type: string } }).polygon.type).toBe(
      'Polygon',
    );
    const geofenceId = (geofence.body as { id: string }).id;

    await request(app!.getHttpServer())
      .delete(`/geofences/${geofenceId}`)
      .set('Authorization', `Bearer ${operatorToken}`)
      .expect(204);

    const users = await request(app!.getHttpServer())
      .get('/users')
      .query({ role: UserRole.FLEET_OPERATOR })
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    const operator = (
      users.body as Array<{ id: string; email: string | null }>
    ).find((row) => row.email === operatorEmail);
    expect(operator).toBeDefined();

    await request(app!.getHttpServer())
      .patch(`/users/${operator!.id}/suspension`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ suspended: true })
      .expect(200);

    await request(app!.getHttpServer())
      .get('/geofences')
      .set('Authorization', `Bearer ${operatorToken}`)
      .expect(401);

    await request(app!.getHttpServer())
      .post('/auth/login')
      .send({ email: operatorEmail, password: 'secreto12' })
      .expect(403);

    await request(app!.getHttpServer())
      .patch(`/users/${operator!.id}/suspension`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ suspended: false })
      .expect(200);

    const reactivated = await request(app!.getHttpServer())
      .get('/users')
      .query({ role: UserRole.FLEET_OPERATOR })
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(
      (
        reactivated.body as Array<{ email: string | null; status: string }>
      ).find((row) => row.email === operatorEmail)?.status,
    ).toBe(UserStatus.ACTIVE);
  }, 60_000);
});
