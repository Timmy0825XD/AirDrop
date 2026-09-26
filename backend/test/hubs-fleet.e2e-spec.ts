import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { UserRole } from '../src/common/enums/user-role.enum';
import { HubStatus } from '../src/common/enums/hub-status.enum';
import { HubType } from '../src/common/enums/hub-type.enum';
import { DroneStatus } from '../src/common/enums/drone-status.enum';
import { WINGCOPTER_198_CODE } from '../src/fleet/drone-model-seed.service';
import {
  andresLopez,
  clinicPayload,
  createStaff,
  dianaHerrera,
  DRONE_VUP_02,
  DRONE_VUP_03,
  hubPayload,
  loginAdmin,
  registerRequester,
  removeFixtures,
  santiagoMora,
} from './e2e-helpers';

const envFile = resolve(__dirname, '..', '.env');
if (existsSync(envFile)) {
  process.loadEnvFile(envFile);
}

const describeIfDb = process.env.DATABASE_URL ? describe : describe.skip;

describeIfDb('Hubs y flota (e2e)', () => {
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

  it('el admin crea centrales activas y el operador solo usa las suyas', async () => {
    const adminToken = await loginAdmin(app!);
    const requesterToken = await registerRequester(app!, andresLopez);

    await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${requesterToken}`)
      .send(hubPayload)
      .expect(403);

    const hospital = await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(hubPayload)
      .expect(201);
    expect(hospital.body).toMatchObject({
      name: hubPayload.name,
      type: HubType.HOSPITAL,
      status: HubStatus.ACTIVE,
    });
    const hospitalId = (hospital.body as { id: string }).id;

    const clinic = await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(clinicPayload)
      .expect(201);
    const clinicId = (clinic.body as { id: string }).id;

    await request(app!.getHttpServer())
      .post('/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        fullName: dianaHerrera.fullName,
        email: dianaHerrera.email,
        phone: dianaHerrera.phone,
        password: 'Password123',
        role: UserRole.DISPATCHER,
        hubIds: [hospitalId, clinicId],
      })
      .expect(400);

    const dispatcher = await createStaff(
      app!,
      adminToken,
      dianaHerrera,
      UserRole.DISPATCHER,
      [hospitalId],
    );

    await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${dispatcher.token}`)
      .send(hubPayload)
      .expect(403);

    const mine = await request(app!.getHttpServer())
      .get('/hubs/me')
      .set('Authorization', `Bearer ${dispatcher.token}`)
      .expect(200);
    expect((mine.body as { id: string }).id).toBe(hospitalId);

    const operator = await createStaff(
      app!,
      adminToken,
      santiagoMora,
      UserRole.FLEET_OPERATOR,
      [hospitalId, clinicId],
    );

    const models = await request(app!.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operator.token}`)
      .expect(200);
    const wingcopter = (
      models.body as Array<{ id: string; code: string }>
    ).find((row) => row.code === WINGCOPTER_198_CODE);
    expect(wingcopter).toBeDefined();

    await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        identifier: DRONE_VUP_02,
        droneModelId: wingcopter!.id,
        hubId: '00000000-0000-4000-8000-000000000000',
      })
      .expect(404);

    const first = await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        identifier: DRONE_VUP_02,
        droneModelId: wingcopter!.id,
        hubId: hospitalId,
      })
      .expect(201);
    expect(first.body).toMatchObject({
      identifier: DRONE_VUP_02,
      status: DroneStatus.AVAILABLE,
      hubId: hospitalId,
    });

    const second = await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        identifier: DRONE_VUP_03,
        droneModelId: wingcopter!.id,
        hubId: clinicId,
      })
      .expect(201);
    expect((second.body as { hubId: string }).hubId).toBe(clinicId);

    await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        identifier: DRONE_VUP_02,
        droneModelId: wingcopter!.id,
        hubId: hospitalId,
      })
      .expect(409);
  }, 40_000);
});
