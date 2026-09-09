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

const envFile = resolve(__dirname, '..', '.env');
if (existsSync(envFile)) {
  process.loadEnvFile(envFile);
}

const describeIfDb = process.env.DATABASE_URL ? describe : describe.skip;

const hubPayload = {
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.46314,
  longitude: -73.25322,
  contactPhone: '3001234567',
};

async function registerVerified(
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
  }, 20_000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('despachador registra central; solicitante no puede; operador da de alta un Wingcopter', async () => {
    const stamp = Date.now();
    const dispatcherToken = await registerVerified(
      app!,
      UserRole.DISPATCHER,
      `despacho.e2e.${stamp}@hospital.co`,
    );
    const requesterToken = await registerVerified(
      app!,
      UserRole.REQUESTER,
      `solicita.e2e.${stamp}@correo.co`,
    );
    const operatorToken = await registerVerified(
      app!,
      UserRole.FLEET_OPERATOR,
      `flota.e2e.${stamp}@hospital.co`,
    );

    await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${requesterToken}`)
      .send(hubPayload)
      .expect(403);

    const created = await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .send(hubPayload)
      .expect(201);

    expect(created.body).toMatchObject({
      name: hubPayload.name,
      type: HubType.HOSPITAL,
      status: HubStatus.PENDING_APPROVAL,
    });
    const hubId = (created.body as { id: string }).id;

    await request(app!.getHttpServer())
      .post('/hubs')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .send(hubPayload)
      .expect(409);

    const mine = await request(app!.getHttpServer())
      .get('/hubs/me')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .expect(200);
    expect((mine.body as { id: string }).id).toBe(hubId);

    const models = await request(app!.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operatorToken}`)
      .expect(200);
    const wingcopter = (
      models.body as Array<{ id: string; code: string }>
    ).find((row) => row.code === WINGCOPTER_198_CODE);
    expect(wingcopter).toBeDefined();

    await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${dispatcherToken}`)
      .send({
        identifier: `WC-${stamp}`,
        droneModelId: wingcopter!.id,
        hubId,
      })
      .expect(403);

    await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({
        identifier: `WC-MISS-${stamp}`,
        droneModelId: wingcopter!.id,
        hubId: '00000000-0000-4000-8000-000000000000',
      })
      .expect(404);

    const identifier = `WC-${stamp}`;
    const drone = await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({
        identifier,
        droneModelId: wingcopter!.id,
        hubId,
      })
      .expect(201);
    expect(drone.body).toMatchObject({
      identifier,
      status: DroneStatus.AVAILABLE,
      hubId,
    });

    await request(app!.getHttpServer())
      .post('/fleet/drones')
      .set('Authorization', `Bearer ${operatorToken}`)
      .send({
        identifier,
        droneModelId: wingcopter!.id,
        hubId,
      })
      .expect(409);

    const listed = await request(app!.getHttpServer())
      .get('/fleet/drones')
      .query({ hubId })
      .set('Authorization', `Bearer ${operatorToken}`)
      .expect(200);
    expect(
      (listed.body as Array<{ identifier: string }>).some(
        (row) => row.identifier === identifier,
      ),
    ).toBe(true);
  }, 40_000);
});
