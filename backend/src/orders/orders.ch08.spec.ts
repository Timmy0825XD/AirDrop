/**
 * Prueba de integración CH-08 (hilo Interfaz – Inventario – Pedidos – BD) de
 * la Segunda Parte. La caída de la base de datos se SIMULA: el repositorio de
 * pedidos lanza un error al guardar, como lo haría una conexión perdida. Las
 * peticiones pasan por el controlador real, el ValidationPipe y los guards de
 * rol (la sesión del solicitante se inyecta en lugar del JWT).
 */
import {
  ExecutionContext,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DocumentType } from '../common/enums/document-type.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { DecisionService } from '../decision/decision.service';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { PlanAgendaService } from './plan-agenda.service';
import { OrdersService } from './orders.service';

// @nestjs/swagger se publica como ESM y Jest (CommonJS) no lo carga. Sus
// decoradores solo documentan la API, así que aquí no hacen nada.
jest.mock('@nestjs/swagger', () => ({
  ApiTags: () => () => undefined,
  ApiBearerAuth: () => () => undefined,
}));

const solicitante = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  role: UserRole.REQUESTER,
  status: UserStatus.ACTIVE,
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1099000001',
  hubAssignments: [],
} as unknown as User;

/** Datos V1 de la guía. */
const urgenciaV1 = {
  medicationName: 'Acetaminofén 500 mg',
  saleType: SaleType.OVER_THE_COUNTER,
  description: 'Fiebre alta persistente',
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4802,
  longitude: -73.2475,
};

const acetaminofen = {
  name: 'Acetaminofén 500 mg',
  saleType: SaleType.OVER_THE_COUNTER,
  requiresColdChain: false,
  availableQuantity: 120,
};

describe('CH-08 — Interfaz – Inventario – Pedidos – BD (base de datos caída, simulada)', () => {
  let app: INestApplication<App>;
  /** Lo que la "base de datos" tiene guardado. */
  const guardados: Order[] = [];
  let baseCaida = false;

  const pedidos = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) => {
      if (baseCaida) {
        return Promise.reject(new Error('Connection terminated unexpectedly'));
      }
      guardados.push(value);
      return Promise.resolve(value);
    }),
    find: jest.fn(() => Promise.resolve([...guardados])),
  };

  beforeAll(async () => {
    const offers = {
      catalog: jest.fn().mockResolvedValue([acetaminofen]),
      offer: jest.fn().mockResolvedValue(acetaminofen),
    } as unknown as InventoryOfferQuery;
    const service = new OrdersService(
      pedidos as never,
      {} as never,
      {} as never,
      {} as never,
      offers,
      {} as HubsService,
      {} as never,
    );
    const decision = {
      attachAssignments: (rows: object[]) =>
        Promise.resolve(rows.map((row) => ({ ...row, assignment: null }))),
    };
    const moduleRef = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: OrdersService, useValue: service },
        { provide: DecisionService, useValue: decision },
        {
          provide: PlanAgendaService,
          useValue: { withCapacity: (plan: object) => plan },
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          context.switchToHttp().getRequest<{ user: User }>().user =
            solicitante;
          return true;
        },
      })
      .compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    // El error 500 es el esperado: se silencia el registro de Nest en la salida.
    app.useLogger(false);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('CH-08 paso 1: «Pedir una urgencia» muestra el catálogo', async () => {
    const respuesta = await request(app.getHttpServer()).get('/orders/catalog');

    expect(respuesta.status).toBe(200);
    expect(respuesta.body).toEqual([
      {
        name: 'Acetaminofén 500 mg',
        saleType: SaleType.OVER_THE_COUNTER,
        requiresColdChain: false,
      },
    ]);
  });

  it('CH-08 pasos 2 a 4: con la base caída, la urgencia responde error del servidor y no se crea', async () => {
    baseCaida = true;

    const respuesta = await request(app.getHttpServer())
      .post('/orders/emergencies')
      .send(urgenciaV1);

    // Pedidos recibió la solicitud e intentó guardarla.
    expect(pedidos.save).toHaveBeenCalledTimes(1);
    expect(respuesta.status).toBe(500);
    expect((respuesta.body as { message: string }).message).toBe(
      'Internal server error',
    );
    expect(guardados).toHaveLength(0);
  });

  it('CH-08 paso 5: al reconectar la base, «Mis pedidos» no muestra ningún pedido nuevo', async () => {
    baseCaida = false;

    const respuesta = await request(app.getHttpServer()).get('/orders/mine');

    expect(respuesta.status).toBe(200);
    expect(respuesta.body).toEqual([]);
  });
});
