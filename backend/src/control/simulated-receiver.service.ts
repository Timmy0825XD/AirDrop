import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DeliveryService } from '../delivery/delivery.service';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { User } from '../users/user.entity';
import { isControlEnabled } from './control.rules';
import { ACTOR_SWEEP_MS, Random, receiverCodeAt } from './sim-actors.rules';

type Plan = {
  /** Aterrizaje con el que se decidió: tras un nuevo despacho, se decide otra vez. */
  landedAtMs: number;
  /** `null`: esta vez deja vencer los 5 minutos (RF-30). */
  codeAtMs: number | null;
};

/**
 * RF-37: el receptor simulado. En los pedidos de los solicitantes simulados,
 * cuando el dron aterriza decide si llega a tiempo (85 %) y, si llega, lee el
 * código y lo ingresa con `DeliveryService`, como haría la persona en la app.
 * Si no llega, no hace nada: los 5 minutos vencen y el dron vuelve con el
 * paquete por el camino de siempre.
 */
@Injectable()
export class SimulatedReceiverService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(SimulatedReceiverService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;
  private readonly plans = new Map<string, Plan>();
  /** RF-36: pedidos en los que nadie va a retirar el paquete. */
  private readonly noShows = new Set<string>();
  /** Los tests lo cambian por uno fijo. */
  random: Random = Math.random;

  constructor(
    private readonly config: ConfigService,
    private readonly delivery: DeliveryService,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Mission)
    private readonly missions: Repository<Mission>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
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

  /** RF-40: el reinicio borra los pedidos; sus decisiones también. */
  forget(): void {
    this.plans.clear();
    this.noShows.clear();
  }

  /**
   * RF-36, "nadie retira el paquete": elige un pedido generado que todavía
   * vuela hacia su destino y deja dicho que el receptor no llegará. Al
   * aterrizar corren los 5 minutos (RF-30). `null` si no hay ninguno.
   */
  async markNoShow(): Promise<string | null> {
    const flying = await this.orders
      .createQueryBuilder('o')
      .innerJoin(User, 'requester', 'requester.id = o.requesterId')
      .where('o.status = :status', { status: OrderStatus.IN_FLIGHT })
      .andWhere('requester.simulated = true')
      .getMany();
    const open = flying.filter((order) => !this.noShows.has(order.id));
    if (!open.length) {
      return null;
    }
    const chosen =
      open[Math.min(open.length - 1, Math.floor(this.random() * open.length))];
    this.noShows.add(chosen.id);
    return chosen.id;
  }

  async runDue(now = simClock.now()): Promise<void> {
    if (this.running) {
      return;
    }
    this.running = true;
    try {
      const waiting = await this.orders
        .createQueryBuilder('o')
        .innerJoin(User, 'requester', 'requester.id = o.requesterId')
        .where('o.status = :status', {
          status: OrderStatus.AWAITING_DELIVERY,
        })
        .andWhere('requester.simulated = true')
        .getMany();
      this.dropFinished(waiting.map((order) => order.id));
      for (const order of waiting) {
        await this.handle(order, now);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'consulta';
      this.logger.error(`El receptor simulado no pudo revisar: ${message}`);
    } finally {
      this.running = false;
    }
  }

  private async handle(order: Order, now: Date): Promise<void> {
    // RF-35: tras un incidente hay más de una misión; la vigente es la última.
    const mission = await this.missions.findOne({
      where: { orderId: order.id },
      order: { startedAt: 'DESC' },
    });
    if (!mission?.landedAt || !order.requesterId) {
      return;
    }
    const landedAtMs = mission.landedAt.getTime();
    let plan = this.plans.get(order.id);
    if (!plan || plan.landedAtMs !== landedAtMs) {
      const codeAt = this.noShows.has(order.id)
        ? null
        : receiverCodeAt(mission.landedAt, this.random);
      plan = { landedAtMs, codeAtMs: codeAt?.getTime() ?? null };
      this.plans.set(order.id, plan);
    }
    if (plan.codeAtMs == null || now.getTime() < plan.codeAtMs) {
      return;
    }
    // Una sola vez: si el servicio lo rechaza, el receptor no insiste.
    plan.codeAtMs = null;
    const requester = await this.users.findOne({
      where: { id: order.requesterId },
    });
    if (!requester) {
      return;
    }
    try {
      const { code } = await this.delivery.show(requester, order.id);
      await this.delivery.validate(requester, order.id, { code });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'código';
      this.logger.warn(
        `El receptor simulado no entregó ${order.id}: ${message}`,
      );
    }
  }

  private dropFinished(waitingIds: string[]): void {
    const alive = new Set(waitingIds);
    for (const id of [...this.plans.keys()]) {
      if (!alive.has(id)) {
        this.plans.delete(id);
        this.noShows.delete(id);
      }
    }
  }
}
