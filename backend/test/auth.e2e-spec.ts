import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { UserRole } from '../src/common/enums/user-role.enum';

const envFile = resolve(__dirname, '..', '.env');
if (existsSync(envFile)) {
  process.loadEnvFile(envFile);
}

const describeIfDb = process.env.DATABASE_URL ? describe : describe.skip;

describeIfDb('Auth (e2e)', () => {
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
      }),
    );
    await app.init();
  }, 20_000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('register → verify-otp → login → me', async () => {
    const email = `ana.e2e.${Date.now()}@correo.co`;
    const password = 'secreto12';

    const register = await request(app!.getHttpServer())
      .post('/auth/register')
      .send({
        fullName: 'Ana Pérez',
        email,
        password,
        role: UserRole.REQUESTER,
        consentAccepted: true,
      })
      .expect(201);

    const otp = (register.body as { otp: string }).otp;
    expect(otp).toMatch(/^\d{6}$/);

    const verified = await request(app!.getHttpServer())
      .post('/auth/verify-otp')
      .send({ email, code: otp })
      .expect(201);

    expect((verified.body as { accessToken: string }).accessToken).toBeDefined();

    const login = await request(app!.getHttpServer())
      .post('/auth/login')
      .send({ email, password })
      .expect(200);

    const loginToken = (login.body as { accessToken: string }).accessToken;

    const me = await request(app!.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${loginToken}`)
      .expect(200);

    expect(me.body).toMatchObject({
      email,
      role: UserRole.REQUESTER,
      status: 'active',
    });
  }, 20_000);
});
