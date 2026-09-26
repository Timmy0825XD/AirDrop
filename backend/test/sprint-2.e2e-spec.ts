import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { SaleType } from '../src/common/enums/sale-type.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
import { DroneStatus } from '../src/common/enums/drone-status.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { WINGCOPTER_198_CODE } from '../src/fleet/drone-model-seed.service';
import {
  camilaDiaz,
  createStaff,
  DRONE_VUP_01,
  hubPayload,
  julianRojas,
  lauraGomez,
  loginAdmin,
  registerRequester,
  removeFixtures,
  TEST_PASSWORD,
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
    await removeFixtures(app);
  }, 20_000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('inventario, flota, geovalla y suspensión de central y operador', async () => {
    const adminToken = await loginAdmin(app!);
    const requesterToken = await registerRequester(app!, camilaDiaz);

    const profile = await request(app!.getHttpServer())
      .patch('/auth/me')
      .set('Authorization', `Bearer ${requesterToken}`)
      .send({ fullName: 'Camila Díaz Rueda' })
      .expect(200);
    expect((profile.body as { fullName: string }).fullName).toBe(
      'Camila Díaz Rueda',
    );

    const hub = await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(hubPayload)
      .expect(201);
    const hubId = (hub.body as { id: string }).id;

    const dispatcher = await createStaff(
      app!,
      adminToken,
      lauraGomez,
      UserRole.DISPATCHER,
      [hubId],
    );
    const operator = await createStaff(
      app!,
      adminToken,
      julianRojas,
      UserRole.FLEET_OPERATOR,
      [hubId],
    );

    const item = await request(app!.getHttpServer())
      .post('/inventory')
      .set('Authorization', `Bearer ${dispatcher.token}`)
      .send({
        name: 'Paracetamol 500 mg',
        quantity: 10,
        lot: 'L-2026-014',
        expirationDate: '2027-03-01',
        requiresColdChain: false,
        saleType: SaleType.PRESCRIPTION,
      })
      .expect(201);
    expect(item.body).toMatchObject({
      name: 'Paracetamol 500 mg',
      lot: 'L-2026-014',
      saleType: SaleType.PRESCRIPTION,
      requiresColdChain: false,
    });

    await request(app!.getHttpServer())
      .patch(`/hubs/${hubId}/suspension`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ suspended: true })
      .expect(200);

    const blocked = await request(app!.getHttpServer())
      .post('/inventory')
      .set('Authorization', `Bearer ${dispatcher.token}`)
      .send({
        name: 'Suero oral',
        quantity: 4,
        lot: 'L-2026-020',
        expirationDate: '2027-06-01',
        requiresColdChain: false,
        saleType: SaleType.OVER_THE_COUNTER,
      });
    console.error('blocked-inventory', blocked.status, blocked.body);
    expect(blocked.status).toBe(403);

    await request(app!.getHttpServer())
      .patch(`/hubs/${hubId}/suspension`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ suspended: false })
      .expect(200);

    const models = await request(app!.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operator.token}`)
      .expect(200);
    const wingcopter = (
      models.body as Array<{ id: string; code: string }>
    ).find((row) => row.code === WINGCOPTER_198_CODE);

    const drone = await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        identifier: DRONE_VUP_01,
        droneModelId: wingcopter!.id,
        hubId,
      })
      .expect(201);
    const droneId = (drone.body as { id: string }).id;

    await request(app!.getHttpServer())
      .patch(`/fleet/drones/${droneId}/status`)
      .set('Authorization', `Bearer ${operator.token}`)
      .send({ status: DroneStatus.MAINTENANCE })
      .expect(200);

    const maintained = await request(app!.getHttpServer())
      .post(`/fleet/drones/${droneId}/maintenance`)
      .set('Authorization', `Bearer ${operator.token}`)
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
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        name: 'Plaza Alfonso López',
        reason: 'Zona restringida de vuelo',
        polygon: valleduparPolygon,
      })
      .expect(201);
    const geofenceId = (geofence.body as { id: string }).id;

    await request(app!.getHttpServer())
      .delete(`/geofences/${geofenceId}`)
      .set('Authorization', `Bearer ${operator.token}`)
      .expect(204);

    await request(app!.getHttpServer())
      .patch(`/users/${operator.id}/suspension`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ suspended: true })
      .expect(200);

    await request(app!.getHttpServer())
      .get('/geofences')
      .set('Authorization', `Bearer ${operator.token}`)
      .expect(401);

    await request(app!.getHttpServer())
      .post('/auth/login')
      .send({ email: julianRojas.email, password: TEST_PASSWORD })
      .expect(403);

    await request(app!.getHttpServer())
      .patch(`/users/${operator.id}/suspension`)
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
      ).find((row) => row.email === julianRojas.email)?.status,
    ).toBe(UserStatus.ACTIVE);
  }, 60_000);
});