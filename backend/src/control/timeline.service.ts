import { randomUUID } from 'node:crypto';
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import {
  TelemetryEvent,
  TelemetryPublisher,
} from '../telemetry/telemetry.publisher';
import { TelemetryRedis } from '../telemetry/telemetry.redis';
import { isControlEnabled } from './control.rules';
import {
  OrderFacts,
  Position,
  TIMELINE_KEY,
  TIMELINE_MAX,
  TimelineDraft,
  TimelineEntry,
  alertDraft,
  clockDraft,
  queueDraft,
  statusDraft,
} from './timeline.rules';

/** Tope de pedidos recordados para no contar dos veces el mismo paso. */
const MAX_REMEMBERED = 5_000;

/**
 * RF-39: escucha los eventos que el sistema ya publica (estado del pedido,
 * cola, alerta, reloj), los cuenta en español, los guarda en Redis con tope
 * y los publica en la sala del radar. No decide nada del negocio.
 */
@Injectable()
export class TimelineService implements OnModuleInit {
  private readonly logger = new Logger(TimelineService.name);
  /** Uno a la vez: así las entradas quedan en el orden en que pasaron. */
  private chain: Promise<void> = Promise.resolve();
  private readonly lastStatus = new Map<string, OrderStatus>();
  private readonly queued = new Set<string>();

  constructor(
    private readonly config: ConfigService,
    private readonly redis: TelemetryRedis,
    private readonly publisher: TelemetryPublisher,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
  ) {}

  onModuleInit(): void {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    this.publisher.onEvent((event) => {
      this.chain = this.chain
        .then(() => this.handle(event))
        .catch((error: unknown) => {
          const message = error instanceof Error ? error.message : 'evento';
          this.logger.warn(
            `No se pudo contar en la línea de tiempo: ${message}`,
          );
        });
    });
  }

  async recent(limit: number): Promise<TimelineEntry[]> {
    const rows = await this.redis.readList(TIMELINE_KEY, limit);
    return rows.flatMap((raw) => {
      try {
        return [JSON.parse(raw) as TimelineEntry];
      } catch {
        return [];
      }
    });
  }

  async handle(event: TelemetryEvent): Promise<void> {
    if (event.type === 'clock') {
      await this.record(clockDraft(event.clock));
      return;
    }
    if (event.type === 'order-status') {
      await this.onStatus(event.orderId, event.status);
      return;
    }
    if (event.type === 'queue-changed') {
      await this.onQueue(event.orderId, event.hubId);
      return;
    }
    if (event.type === 'alert') {
      await this.onAlert(
        event.orderId,
        event.droneId,
        event.kind,
        event.message,
      );
    }
  }

  private async onStatus(orderId: string, status: OrderStatus): Promise<void> {
    if (this.lastStatus.get(orderId) === status) {
      return;
    }
    this.remember(this.lastStatus, () => this.lastStatus.set(orderId, status));
    const order = await this.orders.findOne({ where: { id: orderId } });
    if (!order) {
      return;
    }
    const facts = await this.factsOf(order);
    const draft = statusDraft(status, facts, await this.positionOf(order));
    if (draft) {
      await this.record(draft);
    }
  }

  /** RU-10: solo cuenta la urgencia que entra a una cola, una vez por central. */
  private async onQueue(orderId: string, hubId: string): Promise<void> {
    const key = `${orderId}:${hubId}`;
    if (this.queued.has(key)) {
      return;
    }
    const order = await this.orders.findOne({ where: { id: orderId } });
    if (
      !order ||
      order.status !== OrderStatus.RECEIVED ||
      order.missionType !== MissionType.EMERGENCY
    ) {
      return;
    }
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      return;
    }
    this.remember(this.queued, () => this.queued.add(key));
    await this.record(
      queueDraft(await this.factsOf(order), hub, {
        latitude: hub.latitude,
        longitude: hub.longitude,
      }),
    );
  }

  private async onAlert(
    orderId: string,
    droneId: string,
    kind: Parameters<typeof alertDraft>[0],
    message: string,
  ): Promise<void> {
    const drone = await this.drones.findOne({ where: { id: droneId } });
    const flight = await this.publisher.readFlight(orderId);
    await this.record(
      alertDraft(
        kind,
        message,
        { id: orderId, hubId: drone?.hubId ?? null },
        drone ? { id: drone.id, identifier: drone.identifier } : null,
        flight
          ? { latitude: flight.latitude, longitude: flight.longitude }
          : null,
      ),
    );
  }

  private async record(draft: TimelineDraft): Promise<void> {
    const entry: TimelineEntry = {
      ...draft,
      id: randomUUID(),
      at: simClock.now().toISOString(),
    };
    await this.redis.pushCapped(
      TIMELINE_KEY,
      JSON.stringify(entry),
      TIMELINE_MAX,
    );
    await this.publisher.publish({ type: 'timeline', entry });
  }

  private async factsOf(order: Order): Promise<OrderFacts> {
    const [origin, destination, drone] = await Promise.all([
      order.originHubId
        ? this.hubs.findOne({ where: { id: order.originHubId } })
        : null,
      order.destinationHubId
        ? this.hubs.findOne({ where: { id: order.destinationHubId } })
        : null,
      order.droneId
        ? this.drones.findOne({ where: { id: order.droneId } })
        : null,
    ]);
    return {
      id: order.id,
      missionType: order.missionType,
      destinationKind: order.destinationKind,
      medicationName: order.medicationName,
      fallbackKind: order.fallbackKind,
      originHub: origin ? { id: origin.id, name: origin.name } : null,
      destinationHubName: destination?.name ?? null,
      drone: drone ? { id: drone.id, identifier: drone.identifier } : null,
      decisionTrace: order.decisionTrace,
    };
  }

  /** Donde va el dron si está volando; si no, su central de origen. */
  private async positionOf(order: Order): Promise<Position | null> {
    const flight = await this.publisher.readFlight(order.id);
    if (flight) {
      return { latitude: flight.latitude, longitude: flight.longitude };
    }
    if (!order.originHubId) {
      return null;
    }
    const hub = await this.hubs.findOne({ where: { id: order.originHubId } });
    return hub ? { latitude: hub.latitude, longitude: hub.longitude } : null;
  }

  private remember(store: { size: number; clear(): void }, add: () => void) {
    if (store.size >= MAX_REMEMBERED) {
      store.clear();
    }
    add();
  }
}
