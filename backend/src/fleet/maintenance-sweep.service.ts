import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, LessThan, MoreThanOrEqual, Not, Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { InboxService } from '../notifications/inbox.service';
import { todayInColombia } from '../orders/orders.rules';
import { Drone } from './drone.entity';
import {
  dueNotice,
  maintenanceCycles,
  overdueNotice,
} from './maintenance.rules';

const SWEEP_MS = 10 * 60 * 1000;

/**
 * CU-17: avisa al operador, una sola vez, cuando un mantenimiento se pasó de
 * su fecha y cuando un dron cumple los vuelos del preventivo. Solo avisa: no
 * cambia el estado de ningún dron.
 */
@Injectable()
export class MaintenanceSweepService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MaintenanceSweepService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    private readonly inbox: InboxService,
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
      await this.notifyOverdue(now);
      await this.notifyDue(now);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'mantenimiento';
      this.logger.error(`No se pudo revisar el mantenimiento: ${message}`);
    } finally {
      this.running = false;
    }
  }

  private async notifyOverdue(now: Date): Promise<void> {
    const overdue = await this.drones.find({
      where: {
        status: DroneStatus.MAINTENANCE,
        maintenanceUntil: LessThan(todayInColombia(now)),
        maintenanceOverdueNotifiedAt: IsNull(),
      },
    });
    for (const drone of overdue) {
      await this.inbox.notifyHubOperators(drone.hubId, {
        kind: NotificationKind.MAINTENANCE_OVERDUE,
        ...overdueNotice(drone.identifier, drone.maintenanceUntil as string),
      });
      await this.drones.update(
        { id: drone.id },
        { maintenanceOverdueNotifiedAt: now },
      );
    }
  }

  /** Un dron fuera de servicio no vuela: su preventivo puede esperar. */
  private async notifyDue(now: Date): Promise<void> {
    const due = await this.drones.find({
      where: {
        status: Not(DroneStatus.OUT_OF_SERVICE),
        flightsSinceMaintenance: MoreThanOrEqual(maintenanceCycles()),
        maintenanceDueNotifiedAt: IsNull(),
      },
    });
    for (const drone of due) {
      await this.inbox.notifyHubOperators(drone.hubId, {
        kind: NotificationKind.MAINTENANCE_DUE,
        ...dueNotice(drone.identifier, drone.flightsSinceMaintenance),
      });
      await this.drones.update(
        { id: drone.id },
        { maintenanceDueNotifiedAt: now },
      );
    }
  }
}
