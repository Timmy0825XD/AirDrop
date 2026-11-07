import { randomBytes } from 'node:crypto';
import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { hashPassword } from '../auth/auth.rules';
import { simClock } from '../common/clock/sim-clock';
import { SaleType } from '../common/enums/sale-type.enum';
import { ScheduleKind } from '../common/enums/schedule-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { EmergencyDispatchService } from '../decision/emergency-dispatch.service';
import { OrdersService } from '../orders/orders.service';
import { DESTINATION_IN_GEOFENCE } from '../routing/routing.rules';
import { User } from '../users/user.entity';
import { isControlEnabled } from './control.rules';
import { simulatedDestinations, simulatedRequesters } from './demo-scenario';
import {
  GeneratedKind,
  NO_SIMULATED_DESTINATION,
  NO_SIMULATED_STOCK,
  ORDER_FLOW_EVERY_MS,
  Random,
  flowKind,
  nextScheduledSlot,
  pickOne,
  randomQuantity,
  scatterAround,
} from './sim-actors.rules';
import { SimActorsService } from './sim-actors.service';
import { TimelineService } from './timeline.service';

/** Cuánto se aleja un pedido suelto del centro del barrio. */
const NEIGHBORHOOD_SCATTER_KM = 0.4;
/** Intentos para caer fuera de una geovalla (temporal o tormenta incluidas). */
const PLACEMENT_TRIES = 4;
const DESCRIPTION = 'Pedido de la demostración, de un solicitante simulado.';

export type GeneratedOrder = {
  kind: GeneratedKind;
  /** La urgencia; el programado se sigue por su plan. */
  orderId: string | null;
  planId: string | null;
  address: string;
  latitude: number;
  longitude: number;
};

export type SurgeResult = {
  requested: number;
  created: GeneratedOrder[];
  /** Por qué no salieron las que faltan, tal como lo dijo el servicio. */
  failures: string[];
};

type Point = { address: string; latitude: number; longitude: number };

/**
 * RF-37: el generador de pedidos. Crea urgencias y programados de los
 * solicitantes simulados con `OrdersService`, el mismo camino de la app: si
 * el destino cae en una geovalla o no hay stock, el servicio lo rechaza
 * igual que a una persona. La urgencia entra a la oferta escalonada (RU-10).
 */
@Injectable()
export class OrderGeneratorService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(OrderGeneratorService.name);
  private timer: NodeJS.Timeout | null = null;
  /** Los tests lo cambian por uno fijo. */
  random: Random = Math.random;

  constructor(
    private readonly config: ConfigService,
    private readonly actors: SimActorsService,
    private readonly ordersService: OrdersService,
    private readonly dispatch: EmergencyDispatchService,
    private readonly timeline: TimelineService,
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  onModuleInit(): void {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    this.timer = simClock.every(ORDER_FLOW_EVERY_MS, () => {
      void this.flowTick();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /** CU-39: el administrador pide una urgencia o un programado. */
  async generate(kind: GeneratedKind): Promise<GeneratedOrder> {
    const order = await this.create(kind, () => this.neighborhoodPoint());
    await this.timeline.recordConsole(
      kind === 'emergency'
        ? 'Generador: nueva urgencia simulada'
        : 'Generador: nuevo programado simulado',
      order.address,
    );
    return order;
  }

  /**
   * RF-36: pico de urgencias. Varias seguidas dentro del círculo elegido en
   * el mapa; las que el servicio rechaza se cuentan, no se inventan.
   */
  async surge(
    center: { latitude: number; longitude: number },
    radiusKm: number,
    count: number,
  ): Promise<SurgeResult> {
    const created: GeneratedOrder[] = [];
    const failures: string[] = [];
    for (let index = 0; index < count; index += 1) {
      try {
        created.push(
          await this.create('emergency', () => ({
            address: 'Zona del pico de urgencias, Valledupar',
            ...scatterAround(center, radiusKm, this.random),
          })),
        );
      } catch (error) {
        failures.push(error instanceof Error ? error.message : 'No se creó.');
      }
    }
    await this.timeline.recordConsole(
      `Pico de urgencias: ${created.length} de ${count}`,
      failures.length ? `Sin crear: ${[...new Set(failures)].join(' ')}` : null,
    );
    return { requested: count, created, failures };
  }

  async flowTick(): Promise<void> {
    if (!this.actors.view().orderFlow) {
      return;
    }
    try {
      await this.create(flowKind(this.random), () => this.neighborhoodPoint());
    } catch (error) {
      const message = error instanceof Error ? error.message : 'pedido';
      this.logger.warn(`El flujo de pedidos no creó uno: ${message}`);
    }
  }

  private async create(
    kind: GeneratedKind,
    place: () => Point,
  ): Promise<GeneratedOrder> {
    const requesters = await this.ensureRequesters();
    const requester = pickOne(requesters, this.random);
    const medicationName = await this.pickMedication(requester);
    for (let attempt = 1; ; attempt += 1) {
      const point = place();
      try {
        return kind === 'emergency'
          ? await this.createEmergency(requester, medicationName, point)
          : await this.createScheduled(requester, medicationName, point);
      } catch (error) {
        const blocked =
          error instanceof BadRequestException &&
          error.message === DESTINATION_IN_GEOFENCE;
        if (!blocked) {
          throw error;
        }
        if (attempt >= PLACEMENT_TRIES) {
          throw new BadRequestException(NO_SIMULATED_DESTINATION);
        }
      }
    }
  }

  private async createEmergency(
    requester: User,
    medicationName: string,
    point: Point,
  ): Promise<GeneratedOrder> {
    const created = await this.ordersService.createEmergency(requester, {
      medicationName,
      saleType: SaleType.OVER_THE_COUNTER,
      description: DESCRIPTION,
      ...point,
    });
    // RU-10: igual que el controlador, entra a la cola de la que llega primero.
    await this.dispatch.start(created.id);
    return { kind: 'emergency', orderId: created.id, planId: null, ...point };
  }

  private async createScheduled(
    requester: User,
    medicationName: string,
    point: Point,
  ): Promise<GeneratedOrder> {
    const slot = nextScheduledSlot(simClock.now());
    const plan = await this.ordersService.createPlan(requester, {
      medicationName,
      saleType: SaleType.OVER_THE_COUNTER,
      quantity: randomQuantity(this.random),
      schedule: {
        kind: ScheduleKind.DATES,
        dates: [slot.date],
        time: slot.time,
      },
      ...point,
    });
    // Una sola fecha a más de 2 horas: la entrega nace confirmada (RU-30).
    return { kind: 'scheduled', orderId: null, planId: plan.id, ...point };
  }

  /** Solo venta libre: el solicitante simulado no tiene fórmula que mostrar. */
  private async pickMedication(requester: User): Promise<string> {
    const catalog = (await this.ordersService.catalog(requester, {})) as Array<{
      name: string;
      saleType: SaleType;
    }>;
    const free = catalog.filter(
      (row) => row.saleType === SaleType.OVER_THE_COUNTER,
    );
    if (!free.length) {
      throw new BadRequestException(NO_SIMULATED_STOCK);
    }
    return pickOne(free, this.random).name;
  }

  private neighborhoodPoint(): Point {
    const place = pickOne(simulatedDestinations, this.random);
    return {
      address: place.address,
      ...scatterAround(place, NEIGHBORHOOD_SCATTER_KM, this.random),
    };
  }

  /**
   * Las cuentas simuladas se crean la primera vez que hacen falta, también
   * en una base sembrada antes de esta función. Nadie inicia sesión con
   * ellas: la contraseña es aleatoria y no se guarda en ningún lado.
   */
  private async ensureRequesters(): Promise<User[]> {
    const emails = simulatedRequesters.map((person) => person.email);
    const existing = await this.users.find({ where: { email: In(emails) } });
    const missing = simulatedRequesters.filter(
      (person) => !existing.some((user) => user.email === person.email),
    );
    for (const person of missing) {
      existing.push(
        await this.users.save(
          this.users.create({
            fullName: person.fullName,
            email: person.email,
            phone: null,
            documentType: null,
            documentNumber: null,
            passwordHash: await hashPassword(randomBytes(24).toString('hex')),
            role: UserRole.REQUESTER,
            status: UserStatus.ACTIVE,
            simulated: true,
            // El consentimiento va en hora real, como en el registro.
            consentAcceptedAt: new Date(),
          }),
        ),
      );
    }
    return existing;
  }
}
