import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, LessThan, LessThanOrEqual, Repository } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { InboxService, Notice } from '../notifications/inbox.service';
import { DeliveryPlan } from './delivery-plan.entity';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  REMINDER_LEAD_MS,
  SKIPPED_PAUSED,
  SKIPPED_UNCONFIRMED,
  confirmBy,
  describeSlot,
} from './plan-occurrence.rules';
import { SCHEDULE_LEAD_MS, slotFor } from './plan-schedule.rules';

const SWEEP_MS = 60 * 1000;
const BATCH = 200;

/**
 * Reloj de las entregas programadas (RU-30). A T-24 h avisa y pide
 * confirmar (una central confirma sola); a T-2 h omite lo que nadie
 * confirmó. No autoriza ni reserva dron: eso sigue siendo del despachador.
 */
@Injectable()
export class PlanRemindersService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PlanRemindersService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(DeliveryPlan)
    private readonly plans: Repository<DeliveryPlan>,
    private readonly inbox: InboxService,
    private readonly offers: InventoryOfferQuery,
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
      await this.skipUnconfirmed(now);
      await this.sendReminders(now);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'avisos';
      this.logger.error(`No se pudieron revisar las entregas: ${message}`);
    } finally {
      this.running = false;
    }
  }

  /** T-24 h: avisar, revisar el stock y, si es una central, confirmar. */
  private async sendReminders(now: Date): Promise<void> {
    const due = await this.orders.find({
      where: {
        status: OrderStatus.SCHEDULED,
        scheduledAt: LessThanOrEqual(
          new Date(now.getTime() + REMINDER_LEAD_MS),
        ),
      },
      order: { scheduledAt: 'ASC' },
      take: BATCH,
    });
    const plans = await this.plansOf(due);
    for (const order of due) {
      // Un plan en pausa no avisa: a T-2 h la entrega se omite.
      if (plans.get(order.planId as string)?.paused) {
        continue;
      }
      try {
        await this.remind(order, now);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'aviso';
        this.logger.warn(
          `No se pudo avisar la entrega ${order.id}: ${message}`,
        );
      }
    }
  }

  private async remind(order: Order, now: Date): Promise<void> {
    const toHub = order.destinationKind === DestinationKind.HUB;
    const changes = toHub
      ? { status: OrderStatus.RECEIVED, confirmedAt: now, remindedAt: now }
      : { status: OrderStatus.AWAITING_CONFIRMATION, remindedAt: now };
    const result = await this.orders.update(
      { id: order.id, status: OrderStatus.SCHEDULED, remindedAt: IsNull() },
      changes,
    );
    if (!result.affected) {
      return;
    }
    const slot = describeSlotOf(order);
    if (toHub) {
      await this.toRecipient(order, {
        kind: NotificationKind.INCOMING_SUPPLY,
        orderId: order.id,
        title: 'Llega un abastecimiento programado',
        body: `Llega a tu central el ${slot}. Ten lista la remisión para recibirlo.`,
      });
      if (order.originHubId) {
        await this.inbox.notifyHubDispatchers(order.originHubId, {
          kind: NotificationKind.DISPATCH_SOON,
          orderId: order.id,
          title: 'Tienes un abastecimiento por despachar',
          body: `Sale de tu central el ${slot}. Autoriza y carga desde 2 horas antes.`,
        });
      }
    } else {
      await this.toRecipient(order, {
        kind: NotificationKind.CONFIRM_DELIVERY,
        orderId: order.id,
        title: 'Confirma tu entrega programada',
        body: `Llega el ${slot}. Confírmala en la app antes de las ${confirmBy(startOf(order))}; si no, el dron no sale.`,
      });
    }
    await this.warnIfShort(order, slot);
  }

  /** La central puede reponer antes de la franja: es un aviso, no un bloqueo. */
  private async warnIfShort(order: Order, slot: string): Promise<void> {
    const offer = await this.offers.offer(
      order.medicationName,
      order.saleType,
      order.originHubId ?? undefined,
    );
    if (offer && offer.availableQuantity >= order.quantity) {
      return;
    }
    await this.toRecipient(order, {
      kind: NotificationKind.STOCK_WARNING,
      orderId: order.id,
      title: 'Puede faltar stock para tu entrega',
      body: `Hoy no hay unidades suficientes para la entrega del ${slot}. Te avisamos si no puede salir.`,
    });
  }

  /**
   * T-2 h: lo que sigue sin confirmar se omite. Con el plan en pausa también
   * se omite lo ya confirmado que todavía no tiene dron.
   */
  private async skipUnconfirmed(now: Date): Promise<void> {
    const deadline = LessThan(new Date(now.getTime() + SCHEDULE_LEAD_MS));
    const unconfirmed = await this.orders.find({
      where: {
        status: In([OrderStatus.SCHEDULED, OrderStatus.AWAITING_CONFIRMATION]),
        scheduledAt: deadline,
      },
      take: BATCH,
    });
    const pausedPlans = await this.plans.find({
      where: { paused: true },
      select: { id: true },
    });
    const confirmedButPaused = pausedPlans.length
      ? await this.orders.find({
          where: {
            planId: In(pausedPlans.map((plan) => plan.id)),
            status: OrderStatus.RECEIVED,
            droneId: IsNull(),
            fallbackKind: IsNull(),
            scheduledAt: deadline,
          },
          take: BATCH,
        })
      : [];
    const late = [...unconfirmed, ...confirmedButPaused];
    const plans = await this.plansOf(late);
    for (const order of late) {
      const paused = plans.get(order.planId as string)?.paused ?? false;
      const result = await this.orders.update(
        { id: order.id, status: order.status, droneId: IsNull() },
        {
          status: OrderStatus.SKIPPED,
          statusReason: paused ? SKIPPED_PAUSED : SKIPPED_UNCONFIRMED,
        },
      );
      if (!result.affected) {
        continue;
      }
      await this.toRecipient(order, {
        kind: NotificationKind.DELIVERY_SKIPPED,
        orderId: order.id,
        title: 'Una entrega programada no sale',
        body: paused
          ? `La entrega del ${describeSlotOf(order)} no sale porque el plan está en pausa.`
          : `La entrega del ${describeSlotOf(order)} no sale porque no se confirmó a tiempo.`,
      });
    }
  }

  private async toRecipient(order: Order, notice: Notice): Promise<void> {
    if (order.destinationKind === DestinationKind.HUB) {
      if (order.destinationHubId) {
        await this.inbox.notifyHubDispatchers(order.destinationHubId, notice);
      }
      return;
    }
    if (order.requesterId) {
      await this.inbox.notifyUser(order.requesterId, notice);
    }
  }

  private async plansOf(orders: Order[]): Promise<Map<string, DeliveryPlan>> {
    const ids = [
      ...new Set(orders.map((order) => order.planId).filter(Boolean)),
    ] as string[];
    if (!ids.length) {
      return new Map();
    }
    const rows = await this.plans.find({ where: { id: In(ids) } });
    return new Map(rows.map((plan) => [plan.id, plan]));
  }
}

function startOf(order: Order): Date {
  return (
    order.scheduledAt ?? slotFor(order.scheduledFor as string, null).scheduledAt
  );
}

function describeSlotOf(order: Order): string {
  const slot = slotFor(order.scheduledFor as string, null);
  return describeSlot(
    order.scheduledAt ?? slot.scheduledAt,
    order.windowEndsAt ?? slot.windowEndsAt,
  );
}
