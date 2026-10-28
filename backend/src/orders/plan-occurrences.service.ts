import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { User } from '../users/user.entity';
import { RescheduleOccurrenceDto } from './dto/reschedule-occurrence.dto';
import { Order } from './order.entity';
import { presentOrder } from './order.presenter';
import {
  NOTHING_TO_CONFIRM,
  NOT_YET_AUTHORIZED,
  OCCURRENCE_LOCKED,
  SKIPPED_BY_RECIPIENT,
  assertChangeable,
  assertRecipient,
  rescheduledSlot,
} from './plan-occurrence.rules';

const AWAITING_ANSWER = [
  OrderStatus.SCHEDULED,
  OrderStatus.AWAITING_CONFIRMATION,
];

/**
 * RU-30: lo que hace quien recibe con una entrega de su plan, hasta 2 horas
 * antes de la franja. Cada cambio es un UPDATE condicionado al estado, para
 * no pisar una autorización que llegue al mismo tiempo.
 */
@Injectable()
export class PlanOccurrencesService {
  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
  ) {}

  async confirm(user: User, id: string) {
    const order = await this.requireOccurrence(user, id);
    if (!AWAITING_ANSWER.includes(order.status)) {
      throw new BadRequestException(NOTHING_TO_CONFIRM);
    }
    await this.apply(id, AWAITING_ANSWER, {
      status: OrderStatus.RECEIVED,
      confirmedAt: new Date(),
    });
    return this.present(id);
  }

  async skip(user: User, id: string) {
    await this.requireOccurrence(user, id);
    await this.apply(id, NOT_YET_AUTHORIZED, {
      status: OrderStatus.SKIPPED,
      statusReason: SKIPPED_BY_RECIPIENT,
    });
    return this.present(id);
  }

  /** Mover la entrega cuenta como confirmarla: la persona eligió la hora. */
  async reschedule(user: User, id: string, dto: RescheduleOccurrenceDto) {
    const order = await this.requireOccurrence(user, id);
    const now = new Date();
    const slot = rescheduledSlot(order, dto.date, dto.time, now);
    await this.apply(id, NOT_YET_AUTHORIZED, {
      status: OrderStatus.RECEIVED,
      scheduledFor: slot.date,
      scheduledAt: slot.scheduledAt,
      windowEndsAt: slot.windowEndsAt,
      confirmedAt: now,
      remindedAt: order.remindedAt ?? now,
    });
    return this.present(id);
  }

  private async requireOccurrence(user: User, id: string): Promise<Order> {
    const order = await this.orders.findOne({ where: { id } });
    if (!order) {
      throw new NotFoundException('El pedido no existe.');
    }
    assertRecipient(user, order);
    assertChangeable(order, new Date());
    return order;
  }

  private async apply(
    id: string,
    from: OrderStatus[],
    changes: Partial<Order>,
  ): Promise<void> {
    const result = await this.orders.update(
      { id, status: In(from), droneId: IsNull() },
      changes,
    );
    if (!result.affected) {
      throw new BadRequestException(OCCURRENCE_LOCKED);
    }
  }

  private async present(id: string) {
    const order = await this.orders.findOne({ where: { id } });
    return presentOrder(order as Order);
  }
}
