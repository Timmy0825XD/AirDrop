import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { UserRole } from '../src/common/enums/user-role.enum';
import {
  anaPerez,
  loginAdmin,
  marianaCastro,
  registerRequester,
  removeFixtures,
  TEST_PASSWORD,
} from './e2e-helpers';

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
    await removeFixtures(app);
  }, 20_000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('register → verify-otp → login → me', async () => {
    const register = await request(app!.getHttpServer())
      .post('/auth/register')
      .send({
        ...anaPerez,
        password: TEST_PASSWORD,
        consentAccepted: true,
      })
      .expect(201);

    const otp = (register.body as { otp: string }).otp;
    expect(otp).toMatch(/^\d{6}$/);

    const verified = await request(app!.getHttpServer())
      .post('/auth/verify-otp')
      .send({ email: anaPerez.email, code: otp })
      .expect(201);

    expect((verified.body as { accessToken: string }).accessToken).toBeDefined();

    const login = await request(app!.getHttpServer())
      .post('/auth/login')
      .send({ email: anaPerez.email, password: TEST_PASSWORD })
      .expect(200);

    const loginToken = (login.body as { accessToken: string }).accessToken;

    const me = await request(app!.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${loginToken}`)
      .expect(200);

    expect(me.body).toMatchObject({
      email: anaPerez.email,
      phone: anaPerez.phone,
      documentType: anaPerez.documentType,
      documentNumber: anaPerez.documentNumber,
      role: UserRole.REQUESTER,
      status: 'active',
      hubIds: [],
    });

    await request(app!.getHttpServer()).post('/auth/logout').expect(401);

    await request(app!.getHttpServer())
      .post('/auth/logout')
      .set('Authorization', `Bearer ${loginToken}`)
      .expect(204);
  }, 20_000);

  it('rejects a public role and a repeated document', async () => {
    await request(app!.getHttpServer())
      .post('/auth/register')
      .send({
        ...marianaCastro,
        password: TEST_PASSWORD,
        consentAccepted: true,
        role: UserRole.DISPATCHER,
      })
      .expect(400);

    await request(app!.getHttpServer())
      .post('/auth/register')
      .send({
        fullName: 'Pedro Ramírez',
        email: 'pedro.ramirez@gmail.com',
        phone: '3149990011',
        documentType: anaPerez.documentType,
        documentNumber: anaPerez.documentNumber,
        password: TEST_PASSWORD,
        consentAccepted: true,
      })
      .expect(409);
  }, 20_000);

  it('forgot-password → reset-password → login', async () => {
    await registerRequester(app!, marianaCastro);

    const forgot = await request(app!.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email: marianaCastro.email })
      .expect(200);

    const resetOtp = (forgot.body as { otp: string }).otp;
    expect(resetOtp).toMatch(/^\d{6}$/);

    await request(app!.getHttpServer())
      .post('/auth/reset-password')
      .send({
        email: marianaCastro.email,
        code: resetOtp,
        password: TEST_PASSWORD,
      })
      .expect(200);

    await request(app!.getHttpServer())
      .post('/auth/reset-password')
      .send({
        email: marianaCastro.email,
        code: resetOtp,
        password: TEST_PASSWORD,
      })
      .expect(400);

    await request(app!.getHttpServer())
      .post('/auth/login')
      .send({ email: marianaCastro.email, password: 'clave-incorrecta' })
      .expect(401);

    await request(app!.getHttpServer())
      .post('/auth/login')
      .send({ email: marianaCastro.email, password: TEST_PASSWORD })
      .expect(200);

    const unknown = await request(app!.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email: 'persona.desconocida@gmail.com' })
      .expect(200);
    expect(unknown.body).toEqual(forgot.body.message ? { message: forgot.body.message } : unknown.body);
    expect((unknown.body as { message: string }).message).toBe(
      (forgot.body as { message: string }).message,
    );
    expect(unknown.body).not.toHaveProperty('otp');
  }, 20_000);

  it('admin keeps the seed password', async () => {
    const token = await loginAdmin(app!);
    expect(token).toEqual(expect.any(String));
  }, 20_000);
});
