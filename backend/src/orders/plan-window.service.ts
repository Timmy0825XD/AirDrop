import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, LessThanOrEqual, Repository } from 'typeorm';
import { MissionType } from '../common/enums/mission-type.enum';
import { DecisionService } from '../decision/decision.service';
import { Order } from './order.entity';
import { MISSED_STATUSES } from './plan-dispatch.rules';

const SWEEP_MS = 60 * 1000;
const BATCH = 200;

/**
 * Al cerrar la franja sin despegue, pide el fallback de RF-18.
 * No elige dron: eso sigue en DecisionService.
 */
@Injectable()
export class PlanWindowService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PlanWindowService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    private readonly decision: DecisionService,
  ) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      void this.runDue();
    }, SWEEP_MS);
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
          missionType: MissionType.SCHEDULED,
          status: In(MISSED_STATUSES),
          loadConfirmedAt: IsNull(),
          windowEndsAt: LessThanOrEqual(now),
        },
        order: { windowEndsAt: 'ASC' },
        take: BATCH,
      });
      for (const order of due) {
        await this.expire(order.id, now);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'consulta';
      this.logger.error(`No se pudieron cerrar las franjas: ${message}`);
    } finally {
      this.running = false;
    }
  }

  private async expire(orderId: string, now: Date): Promise<void> {
    try {
      await this.decision.expireMissed(orderId, now);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'vencimiento';
      this.logger.warn(`No se pudo vencer ${orderId}: ${message}`);
    }
  }
}
