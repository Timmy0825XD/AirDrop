import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  EntityManager,
  IsNull,
  LessThanOrEqual,
  Not,
  Repository,
} from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { HubStatus } from '../common/enums/hub-status.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { InboxService } from '../notifications/inbox.service';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { Hub } from './hub.entity';
import {
  HUB_ALREADY_WITHOUT_POWER,
  HUB_HAS_POWER,
  SUSPENDED_HUB_OUTAGE,
  isPowered,
  outageEnd,
} from './hub-power.rules';

/** Cada cuánto (en hora simulada) se mira si volvió la energía. */
const RESTORE_SWEEP_MS = 15_000;

/** Lo que se publica de un apagón: la central y hasta cuándo. */
export type HubOutageJson = {
  hubId: string;
  name: string;
  latitude: number;
  longitude: number;
  /** Hora simulada en que vuelve (o volvió) la energía. */
  until: string;
};

/**
 * RF-36 y CU-45: deja una central sin energía por un tiempo (consola o modo
 * caos), la devuelve al vencer y lo cuenta. Quien reubica los pedidos de la
 * central es el motor de decisión, que se suscribe con `onOutageStarted`.
 */
@Injectable()
export class HubOutageService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(HubOutageService.name);
  private timer: NodeJS.Timeout | null = null;
  private readonly startListeners: Array<(hubId: string) => Promise<void>> = [];

  constructor(
    @InjectRepository(Hub) private readonly hubs: Repository<Hub>,
    private readonly publisher: TelemetryPublisher,
    private readonly inbox: InboxService,
  ) {}

  onModuleInit(): void {
    this.timer = simClock.every(RESTORE_SWEEP_MS, () => {
      void this.restoreDue().catch((error: unknown) => {
        const message = error instanceof Error ? error.message : 'energía';
        this.logger.warn(`No se pudo devolver la energía: ${message}`);
      });
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /** CU-45: el motor de decisión mueve los pedidos de la central apagada. */
  onOutageStarted(listener: (hubId: string) => Promise<void>): void {
    this.startListeners.push(listener);
  }

  async active(now = simClock.now()): Promise<HubOutageJson[]> {
    const hubs = await this.hubs.find({
      where: { powerOutageUntil: Not(IsNull()) },
      order: { powerOutageUntil: 'ASC' },
    });
    return hubs
      .filter((hub) => !isPowered(hub, now))
      .map((hub) => presentOutage(hub, now));
  }

  async start(hubId: string, durationMin: number): Promise<HubOutageJson> {
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    if (hub.status !== HubStatus.ACTIVE) {
      throw new BadRequestException(SUSPENDED_HUB_OUTAGE);
    }
    const now = simClock.now();
    if (!isPowered(hub, now)) {
      throw new ConflictException(HUB_ALREADY_WITHOUT_POWER);
    }
    hub.powerOutageUntil = outageEnd(now, durationMin);
    await this.hubs.update(
      { id: hub.id },
      { powerOutageUntil: hub.powerOutageUntil },
    );
    const outage = presentOutage(hub, now);
    await this.publisher.publish({
      type: 'hub-outage',
      action: 'started',
      outage,
    });
    await this.notify(hub, NotificationKind.HUB_OUTAGE, durationMin);
    for (const listener of this.startListeners) {
      try {
        await listener(hub.id);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'pedidos';
        this.logger.error(
          `No se pudieron mover los pedidos de ${hub.name}: ${message}`,
        );
      }
    }
    return outage;
  }

  /** La consola devuelve la energía antes de tiempo. */
  async end(hubId: string): Promise<HubOutageJson> {
    const hub = await this.hubs.findOne({ where: { id: hubId } });
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    const now = simClock.now();
    if (isPowered(hub, now)) {
      throw new NotFoundException(HUB_HAS_POWER);
    }
    return this.restore(hub, now);
  }

  /** RF-36: al vencer, la energía vuelve sola. */
  async restoreDue(now = simClock.now()): Promise<number> {
    const due = await this.hubs.find({
      where: { powerOutageUntil: LessThanOrEqual(now) },
    });
    for (const hub of due) {
      await this.restore(hub, now);
    }
    return due.length;
  }

  /** RF-40: el reinicio devuelve la energía a las centrales sin contarlo. */
  async clearAll(manager: EntityManager): Promise<void> {
    await manager.update(
      Hub,
      { powerOutageUntil: Not(IsNull()) },
      { powerOutageUntil: null },
    );
  }

  private async restore(hub: Hub, now: Date): Promise<HubOutageJson> {
    const outage = presentOutage(hub, now);
    await this.hubs.update({ id: hub.id }, { powerOutageUntil: null });
    await this.publisher.publish({
      type: 'hub-outage',
      action: 'ended',
      outage: { ...outage, until: now.toISOString() },
    });
    await this.notify(hub, NotificationKind.HUB_POWER_RESTORED, null);
    return outage;
  }

  private async notify(
    hub: Hub,
    kind: NotificationKind,
    durationMin: number | null,
  ): Promise<void> {
    try {
      await this.inbox.notifyHubDispatchers(
        hub.id,
        kind === NotificationKind.HUB_OUTAGE
          ? {
              kind,
              title: `${hub.name} sin energía`,
              body: `Por unos ${durationMin} minutos no se puede autorizar ni confirmar cargas. Las urgencias pasan a otra central y los programados se reintentan en su franja.`,
            }
          : {
              kind,
              title: `Volvió la energía a ${hub.name}`,
              body: 'La central ya puede autorizar y confirmar cargas.',
            },
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : 'aviso';
      this.logger.warn(`No se pudo avisar del apagón: ${message}`);
    }
  }
}

function presentOutage(hub: Hub, now: Date): HubOutageJson {
  return {
    hubId: hub.id,
    name: hub.name,
    latitude: hub.latitude,
    longitude: hub.longitude,
    until: (hub.powerOutageUntil ?? now).toISOString(),
  };
}
