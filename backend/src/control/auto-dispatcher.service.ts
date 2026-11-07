import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, LessThanOrEqual, Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { HubStatus } from '../common/enums/hub-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DecisionService } from '../decision/decision.service';
import { Hub } from '../hubs/hub.entity';
import { isPowered } from '../hubs/hub-power.rules';
import { Order } from '../orders/order.entity';
import { OrdersService } from '../orders/orders.service';
import { isControlEnabled } from './control.rules';
import {
  ACTOR_RETRY_MS,
  ACTOR_SWEEP_MS,
  AUTHORIZE_DELAY_MS,
  LOAD_DELAY_MS,
  awaitsAutoAuthorization,
  isDue,
  pickAuthorizingHub,
  turnStartedAt,
} from './sim-actors.rules';
import { SimActorsService } from './sim-actors.service';

/** Tope por barrido, para no tapar el reloj con un pico grande. */
const BATCH = 25;

/**
 * RF-37: el despachador automático. Encendido, en cualquier central activa
 * autoriza lo que le toca a los 10 s simulados y confirma la carga 20 s
 * después, con `DecisionService` como un despachador más. Si el motor dice
 * que no (sin lote, sin energía, fuera de franja), espera y vuelve a probar;
 * nunca se salta una regla.
 */
@Injectable()
export class AutoDispatcherService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AutoDispatcherService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;
  /** Pedido → hora simulada desde la que se puede volver a intentar. */
  private readonly backoff = new Map<string, number>();

  constructor(
    private readonly config: ConfigService,
    private readonly actors: SimActorsService,
    private readonly decision: DecisionService,
    private readonly ordersService: OrdersService,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
  ) {}

  onModuleInit(): void {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    this.timer = simClock.every(ACTOR_SWEEP_MS, () => {
      void this.runDue();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /** RF-40: el reinicio borra los pedidos; sus esperas también. */
  forget(): void {
    this.backoff.clear();
  }

  async runDue(now = simClock.now()): Promise<void> {
    if (this.running || !this.actors.view().autoDispatcher) {
      return;
    }
    this.running = true;
    try {
      const hubs = await this.hubs.find({
        where: { status: HubStatus.ACTIVE },
      });
      const usable = hubs.filter((hub) => isPowered(hub, now));
      await this.authorizeDue(usable, now);
      await this.confirmLoadsDue(usable, now);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'consulta';
      this.logger.error(
        `El despachador automático no pudo revisar: ${message}`,
      );
    } finally {
      this.running = false;
    }
  }

  private async authorizeDue(hubs: Hub[], now: Date): Promise<void> {
    const waiting = await this.orders.find({
      where: {
        status: In([OrderStatus.RECEIVED, OrderStatus.REASSIGNED]),
        droneId: IsNull(),
      },
      order: { createdAt: 'ASC' },
      take: BATCH * 4,
    });
    let tried = 0;
    for (const order of waiting) {
      if (tried >= BATCH) {
        return;
      }
      if (!awaitsAutoAuthorization(order) || this.waitingRetry(order.id, now)) {
        continue;
      }
      const awaiting = new Set(await this.awaitingHubs(order));
      const hubId = pickAuthorizingHub(
        order,
        hubs.filter((hub) => awaiting.has(hub.id)),
      );
      if (
        !hubId ||
        !isDue(turnStartedAt(order, hubId), AUTHORIZE_DELAY_MS, now)
      ) {
        continue;
      }
      tried += 1;
      await this.attempt(order.id, now, () =>
        this.decision.autoAuthorize(hubId, order.id),
      );
    }
  }

  private async confirmLoadsDue(hubs: Hub[], now: Date): Promise<void> {
    if (!hubs.length) {
      return;
    }
    const ready = await this.orders.find({
      where: {
        status: OrderStatus.PENDING_LOAD,
        loadConfirmedAt: IsNull(),
        originHubId: In(hubs.map((hub) => hub.id)),
        authorizedAt: LessThanOrEqual(new Date(now.getTime() - LOAD_DELAY_MS)),
      },
      order: { authorizedAt: 'ASC' },
      take: BATCH,
    });
    for (const order of ready) {
      if (!order.originHubId || this.waitingRetry(order.id, now)) {
        continue;
      }
      const hubId = order.originHubId;
      await this.attempt(order.id, now, () =>
        this.decision.autoConfirmLoad(hubId, order.id),
      );
    }
  }

  /**
   * Las centrales que tienen el pedido en su cola. Con central de origen u
   * oferta escalonada se sabe sin ir al stock; si no, lo dice `OrdersService`.
   */
  private async awaitingHubs(order: Order): Promise<string[]> {
    if (order.originHubId) {
      return [order.originHubId];
    }
    if (order.dispatchOffers) {
      return order.dispatchOffers
        .filter((offer) => offer.offeredAt != null && offer.declinedAt == null)
        .map((offer) => offer.hubId);
    }
    return this.ordersService.hubsAwaiting(order);
  }

  private waitingRetry(orderId: string, now: Date): boolean {
    const until = this.backoff.get(orderId);
    return until != null && until > now.getTime();
  }

  private async attempt(
    orderId: string,
    now: Date,
    action: () => Promise<unknown>,
  ): Promise<void> {
    try {
      await action();
      this.backoff.delete(orderId);
    } catch (error) {
      // El motor dijo que no: un despachador tampoco podría. Se reintenta luego.
      this.backoff.set(orderId, now.getTime() + ACTOR_RETRY_MS);
      const message = error instanceof Error ? error.message : 'error';
      this.logger.debug(`Despachador automático en ${orderId}: ${message}`);
    }
  }
}
