import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThanOrEqual, Repository } from 'typeorm';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { DecisionService } from './decision.service';
import { scheduledRetryMs } from './fallback.rules';

/** Cada cuánto se buscan los programados cuyo reintento ya venció. */
const SWEEP_MS = 60 * 1000;

/**
 * Reloj de los reintentos de RF-18: solo encuentra los programados que
 * esperan dron y le pide a `DecisionService` que los autorice otra vez.
 * No decide nada por su cuenta.
 */
@Injectable()
export class ScheduledRetryService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ScheduledRetryService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    private readonly decision: DecisionService,
  ) {}

  onModuleInit(): void {
    this.timer = setInterval(
      () => {
        void this.runDue();
      },
      Math.min(SWEEP_MS, scheduledRetryMs()),
    );
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async runDue(now = new Date()): Promise<void> {
    if (this.running) {
      return;
    }
    this.running = true;
    try {
      const due = await this.orders.find({
        where: {
          status: OrderStatus.RECEIVED,
          fallbackKind: FallbackKind.RETRY,
          retryAfter: LessThanOrEqual(now),
        },
        order: { retryAfter: 'ASC' },
      });
      for (const order of due) {
        await this.retry(order.id, now);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'consulta';
      this.logger.error(`No se pudieron leer los reintentos: ${message}`);
    } finally {
      this.running = false;
    }
  }

  /** Si el intento falla por otra razón, se corre al siguiente turno. */
  private async retry(orderId: string, now: Date): Promise<void> {
    try {
      await this.decision.retryScheduled(orderId, now);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'reintento';
      this.logger.warn(`No se pudo reintentar ${orderId}: ${message}`);
      await this.orders.update(
        { id: orderId, fallbackKind: FallbackKind.RETRY },
        { retryAfter: new Date(now.getTime() + scheduledRetryMs()) },
      );
    }
  }
}
