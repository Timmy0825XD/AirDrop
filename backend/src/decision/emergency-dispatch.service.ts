import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { DataSource, EntityManager, IsNull, LessThanOrEqual } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { NotificationsService } from '../notifications/notifications.service';
import { FallbackOption, Order } from '../orders/order.entity';
import { todayInColombia } from '../orders/orders.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import {
  DispatchCandidate,
  EVERY_HUB_DECLINED,
  NO_HUB_WITHIN_RANGE,
  ONLY_OPEN_EMERGENCY_IS_DECLINED,
  OfferStep,
  declineOffer,
  everyHubDeclined,
  openNextOffer,
  rankDispatchCandidates,
} from './dispatch.rules';
import { applyConventional, rankHubsByDistance } from './fallback.rules';
import { toOption } from './fallback.service';
import { HubEvaluationService } from './hub-evaluation.service';
import { simClock } from '../common/clock/sim-clock';

/** Cada cuánto (en hora simulada) se buscan las urgencias cuya oferta hay que ampliar. */
const SWEEP_MS = 15 * 1000;

type Notice = {
  orderId: string;
  /** Centrales cuya cola cambió: la que recibe la oferta o la que declinó. */
  hubIds: string[];
  /** La urgencia quedó en traslado convencional. */
  conventional: boolean;
};

/**
 * RU-10: despacho escalonado de las urgencias civiles. Al crearlas, calcula
 * a qué centrales ofrecerlas y en qué orden; con el reloj, amplía la oferta;
 * y recibe el "no puedo atenderla" de una central. No autoriza ni reserva
 * dron: eso sigue siendo de `DecisionService` cuando una central autoriza.
 */
@Injectable()
export class EmergencyDispatchService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EmergencyDispatchService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    private readonly dataSource: DataSource,
    private readonly hubEvaluation: HubEvaluationService,
    private readonly routes: RoutePlannerService,
    private readonly hubsService: HubsService,
    private readonly notifications: NotificationsService,
  ) {}

  onModuleInit(): void {
    this.timer = simClock.every(SWEEP_MS, () => {
      void this.escalateDue();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * Recién creada la urgencia: la ofrece a la central que llega primero. Si
   * ninguna central con el insumo tiene un corredor que la batería alcance,
   * pasa de una vez a traslado convencional (RF-18).
   */
  async start(orderId: string, now = simClock.now()): Promise<Order> {
    const { order, notice } = await this.dataSource.transaction(
      async (manager) => {
        const current = await this.lockOrder(manager, orderId);
        const today = todayInColombia(now);
        const { candidates, withStock } = await this.candidates(
          manager,
          current,
          today,
        );
        if (!candidates.length) {
          return this.toConventional(
            manager,
            current,
            withStock,
            NO_HUB_WITHIN_RANGE,
            now,
            [],
          );
        }
        const step = openNextOffer(rankDispatchCandidates(candidates), now);
        return this.saveStep(manager, current, step, []);
      },
    );
    await this.announce(notice);
    return order;
  }

  /** Amplía la oferta de las urgencias cuya ventaja ya venció. */
  async escalateDue(now = simClock.now()): Promise<void> {
    if (this.running) {
      return;
    }
    this.running = true;
    try {
      const due = await this.dataSource.getRepository(Order).find({
        where: {
          missionType: MissionType.EMERGENCY,
          status: OrderStatus.RECEIVED,
          originHubId: IsNull(),
          nextEscalationAt: LessThanOrEqual(now),
        },
        order: { nextEscalationAt: 'ASC' },
      });
      for (const order of due) {
        await this.escalate(order.id, now);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'consulta';
      this.logger.error(`No se pudieron ampliar las urgencias: ${message}`);
    } finally {
      this.running = false;
    }
  }

  /** "No puedo atenderla": se ofrece en ese instante a la siguiente central. */
  async decline(
    user: User,
    orderId: string,
    reason: string | null,
    now = simClock.now(),
  ): Promise<Order> {
    const hub = await this.requireDispatcherHub(user);
    const { order, notice } = await this.dataSource.transaction(
      async (manager) => {
        const current = await this.lockOrder(manager, orderId);
        if (!isOpenEmergency(current) || !current.dispatchOffers) {
          throw new BadRequestException(ONLY_OPEN_EMERGENCY_IS_DECLINED);
        }
        const step = declineOffer(current.dispatchOffers, hub.id, reason, now);
        if (!everyHubDeclined(step.offers)) {
          return this.saveStep(manager, current, step, [hub.id]);
        }
        current.dispatchOffers = step.offers;
        const { withStock } = await this.candidates(
          manager,
          current,
          todayInColombia(now),
        );
        return this.toConventional(
          manager,
          current,
          withStock,
          EVERY_HUB_DECLINED,
          now,
          [hub.id],
        );
      },
    );
    await this.announce(notice);
    return order;
  }

  private async escalate(orderId: string, now: Date): Promise<void> {
    try {
      const notice = await this.dataSource.transaction(async (manager) => {
        const order = await this.lockOrder(manager, orderId);
        if (
          !isOpenEmergency(order) ||
          !order.dispatchOffers ||
          !order.nextEscalationAt ||
          order.nextEscalationAt > now
        ) {
          return null;
        }
        const step = openNextOffer(order.dispatchOffers, now);
        return (await this.saveStep(manager, order, step, [])).notice;
      });
      if (notice) {
        await this.announce(notice);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'ampliación';
      this.logger.warn(`No se pudo ampliar la urgencia ${orderId}: ${message}`);
    }
  }

  /**
   * Centrales que pueden atender: lote vigente, corredor libre de geovallas
   * y batería que alcanza ida, regreso y reserva. Las que solo tienen el
   * lote quedan para el traslado convencional, de la más cercana a la más
   * lejana.
   */
  private async candidates(
    manager: EntityManager,
    order: Order,
    today: string,
  ): Promise<{ candidates: DispatchCandidate[]; withStock: FallbackOption[] }> {
    const active = await manager.find(Hub, {
      where: { status: HubStatus.ACTIVE },
    });
    const polygons = await this.routes.loadPolygons(manager);
    const ranked = rankHubsByDistance(active, destinationOf(order));
    const candidates: DispatchCandidate[] = [];
    const withStock: FallbackOption[] = [];
    for (const { hub, distanceKm } of ranked) {
      const evaluation = await this.hubEvaluation.evaluate(
        manager,
        hub,
        order,
        today,
        polygons,
        false,
      );
      if (!evaluation.lot) {
        continue;
      }
      withStock.push(toOption(hub, distanceKm));
      if (evaluation.inRange && Number.isFinite(evaluation.etaMs)) {
        candidates.push({
          hubId: hub.id,
          name: hub.name,
          etaMs: Math.round(evaluation.etaMs as number),
          ready: evaluation.choice.chosen != null,
        });
      }
    }
    return { candidates, withStock };
  }

  private async saveStep(
    manager: EntityManager,
    order: Order,
    step: OfferStep,
    changedHubIds: string[],
  ) {
    order.dispatchOffers = step.offers;
    order.nextEscalationAt = step.nextEscalationAt;
    const saved = await manager.save(order);
    const hubIds = step.openedHubId
      ? [...changedHubIds, step.openedHubId]
      : changedHubIds;
    return {
      order: saved,
      notice: { orderId: order.id, hubIds, conventional: false },
    };
  }

  private async toConventional(
    manager: EntityManager,
    order: Order,
    withStock: FallbackOption[],
    reason: string,
    now: Date,
    changedHubIds: string[],
  ) {
    applyConventional(order, null, withStock, now);
    if (order.fallbackOptions?.length) {
      order.fallbackReason = reason;
    }
    order.nextEscalationAt = null;
    const saved = await manager.save(order);
    return {
      order: saved,
      notice: {
        orderId: order.id,
        hubIds: changedHubIds,
        conventional: true,
      },
    };
  }

  /** Avisos por el socket, ya confirmada la transacción. */
  private async announce(notice: Notice): Promise<void> {
    try {
      for (const hubId of notice.hubIds) {
        await this.notifications.queueChanged(hubId, notice.orderId);
      }
      if (notice.conventional) {
        await this.notifications.statusChanged(
          notice.orderId,
          OrderStatus.REASSIGNED,
        );
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'socket';
      this.logger.warn(
        `No se pudo avisar de la urgencia ${notice.orderId}: ${message}`,
      );
    }
  }

  private async lockOrder(
    manager: EntityManager,
    orderId: string,
  ): Promise<Order> {
    const order = await manager.findOne(Order, {
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order) {
      throw new NotFoundException('El pedido no existe.');
    }
    return order;
  }

  private async requireDispatcherHub(user: User): Promise<Hub> {
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException('Solo el despachador declina una urgencia.');
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new ForbiddenException(
        'Debes tener una central asignada para gestionar pedidos.',
      );
    }
    return this.hubsService.requireActive(hubIds[0]);
  }
}

/** Urgencia civil en recibido que todavía no tiene central de origen. */
function isOpenEmergency(order: Order): boolean {
  return (
    order.missionType === MissionType.EMERGENCY &&
    order.destinationKind === DestinationKind.PERSON &&
    order.status === OrderStatus.RECEIVED &&
    order.originHubId == null
  );
}

function destinationOf(order: Order) {
  return {
    longitude: order.longitude as number,
    latitude: order.latitude as number,
  };
}
