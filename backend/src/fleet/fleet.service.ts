import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { HubsService } from '../hubs/hubs.service';
import { todayInColombia } from '../orders/orders.rules';
import { batteryNow } from '../simulation/flight-energy.rules';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CreateDroneDto } from './dto/create-drone.dto';
import { RegisterMaintenanceDto } from './dto/register-maintenance.dto';
import { UpdateDroneStatusDto } from './dto/update-drone-status.dto';
import { Drone } from './drone.entity';
import { DroneMaintenance } from './drone-maintenance.entity';
import { DroneModel } from './drone-model.entity';
import {
  closingResetsCycles,
  isMaintenanceDue,
  isMaintenanceOverdue,
  maintenanceCycles,
  periodKindFor,
} from './maintenance.rules';

type StatusChange = {
  status: DroneStatus;
  reason?: string;
  estimatedEndDate?: string;
};

@Injectable()
export class FleetService {
  constructor(
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    @InjectRepository(DroneModel)
    private readonly models: Repository<DroneModel>,
    @InjectRepository(DroneMaintenance)
    private readonly maintenances: Repository<DroneMaintenance>,
    private readonly hubsService: HubsService,
  ) {}

  async listModels() {
    const rows = await this.models.find({ order: { name: 'ASC' } });
    return rows.map((row) => this.toPublicModel(row));
  }

  async createDrone(user: User, dto: CreateDroneDto) {
    const model = await this.models.findOne({
      where: { id: dto.droneModelId },
    });
    if (!model) {
      throw new NotFoundException('El modelo de dron no existe.');
    }
    await this.hubsService.requireActive(dto.hubId);
    this.assertAssigned(user, dto.hubId);
    const duplicate = await this.drones.findOne({
      where: { identifier: dto.identifier },
    });
    if (duplicate) {
      throw new ConflictException('Ya existe un dron con este identificador.');
    }
    const drone = this.drones.create({
      identifier: dto.identifier,
      droneModelId: model.id,
      hubId: dto.hubId,
      status: DroneStatus.AVAILABLE,
      maintenanceReason: null,
      maintenanceUntil: null,
    });
    const saved = await this.drones.save(drone);
    return this.toPublicDrone(saved);
  }

  /**
   * El operador ve los drones de sus centrales; el administrador, los de
   * cualquier central, solo para consultar (crear y gestionar sigue siendo
   * del operador).
   */
  async listDrones(user: User, hubId: string) {
    if (user.role !== UserRole.ADMIN) {
      this.assertAssigned(user, hubId);
    }
    const hub = await this.hubsService.findById(hubId);
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    const rows = await this.drones.find({
      where: { hubId },
      order: { identifier: 'ASC' },
    });
    return rows.map((row) => this.toPublicDrone(row));
  }

  /**
   * CU-16: disponible, mantenimiento (temporal, con fecha) o fuera de servicio
   * (indefinido). Cada salida de la flota abre un periodo en el historial y
   * volver a disponible lo cierra.
   */
  async updateStatus(user: User, id: string, dto: UpdateDroneStatusDto) {
    const drone = await this.requireOwnDrone(user, id);
    this.assertNotInMission(drone);
    return this.toPublicDrone(await this.applyStatus(drone, user, dto));
  }

  /** CU-17: mantenimiento con motivo y fecha estimada de fin, obligatorios. */
  async registerMaintenance(
    user: User,
    id: string,
    dto: RegisterMaintenanceDto,
  ) {
    const drone = await this.requireOwnDrone(user, id);
    this.assertNotInMission(drone);
    const saved = await this.applyStatus(drone, user, {
      status: DroneStatus.MAINTENANCE,
      reason: dto.reason,
      estimatedEndDate: dto.estimatedEndDate,
    });
    return this.toPublicDrone(saved);
  }

  /** Historial de taller de un dron, del más reciente al más viejo. */
  async listMaintenance(user: User, id: string) {
    const drone = await this.drones.findOne({ where: { id } });
    if (!drone) {
      throw new NotFoundException('El dron no existe.');
    }
    if (user.role !== UserRole.ADMIN) {
      this.assertAssigned(user, drone.hubId);
    }
    const rows = await this.maintenances.find({
      where: { droneId: id },
      order: { startedAt: 'DESC' },
    });
    return rows.map((row) => ({
      id: row.id,
      kind: row.kind,
      reason: row.reason,
      estimatedEndDate: row.estimatedEndDate,
      flightsAtStart: row.flightsAtStart,
      startedAt: row.startedAt,
      closedAt: row.closedAt,
    }));
  }

  private async applyStatus(
    drone: Drone,
    user: User,
    change: StatusChange,
  ): Promise<Drone> {
    const kind = periodKindFor(change.status);
    const open = await this.maintenances.findOne({
      where: { droneId: drone.id, closedAt: IsNull() },
    });
    const reason = change.reason?.trim() || drone.maintenanceReason;
    const until =
      kind === DroneMaintenanceKind.MAINTENANCE
        ? (change.estimatedEndDate ?? drone.maintenanceUntil)
        : null;
    if (until !== drone.maintenanceUntil || change.status !== drone.status) {
      // Otra fecha u otro estado: el aviso de vencido vuelve a contar.
      drone.maintenanceOverdueNotifiedAt = null;
    }
    const samePeriod = kind !== null && open?.kind === kind;
    if (!samePeriod) {
      // Si no hay periodo abierto (datos de antes del historial), el estado
      // del dron dice qué estaba cerrando.
      const closing = open?.kind ?? periodKindFor(drone.status);
      if (open) {
        open.closedAt = new Date();
        open.closedByUserId = user.id;
        await this.maintenances.save(open);
      }
      if (closingResetsCycles(closing)) {
        drone.flightsSinceMaintenance = 0;
        drone.maintenanceDueNotifiedAt = null;
      }
    }
    drone.status = change.status;
    drone.maintenanceReason = kind ? reason : null;
    drone.maintenanceUntil = until;
    const saved = await this.drones.save(drone);
    if (samePeriod && open) {
      open.reason = saved.maintenanceReason;
      open.estimatedEndDate = saved.maintenanceUntil;
      await this.maintenances.save(open);
    } else if (kind) {
      await this.maintenances.save(
        this.maintenances.create({
          droneId: saved.id,
          kind,
          reason: saved.maintenanceReason,
          estimatedEndDate: saved.maintenanceUntil,
          flightsAtStart: saved.flightsSinceMaintenance ?? 0,
          openedByUserId: user.id,
          closedAt: null,
          closedByUserId: null,
        }),
      );
    }
    return saved;
  }

  toPublicModel(model: DroneModel) {
    return {
      id: model.id,
      code: model.code,
      name: model.name,
      maxSpeedKmh: model.maxSpeedKmh,
      maxPayloadKg: model.maxPayloadKg,
      maxRangeKm: model.maxRangeKm,
    };
  }

  toPublicDrone(drone: Drone) {
    return {
      id: drone.id,
      identifier: drone.identifier,
      droneModelId: drone.droneModelId,
      hubId: drone.hubId,
      status: drone.status,
      maintenanceReason: drone.maintenanceReason,
      maintenanceUntil: drone.maintenanceUntil,
      /** Batería ahora, con lo que recargó en tierra desde el último vuelo. */
      batteryPercent: batteryNow(
        drone.batteryPercent ?? 100,
        drone.batteryUpdatedAt ?? null,
        new Date(),
      ),
      lastFlightEndedAt: drone.lastFlightEndedAt ?? null,
      /** CU-17: vuelos desde la última revisión y cada cuántos toca. */
      flightsSinceMaintenance: drone.flightsSinceMaintenance ?? 0,
      maintenanceCycles: maintenanceCycles(),
      maintenanceDue: isMaintenanceDue(drone.flightsSinceMaintenance ?? 0),
      maintenanceOverdue: isMaintenanceOverdue(drone, todayInColombia()),
      createdAt: drone.createdAt,
    };
  }

  private async requireOwnDrone(user: User, id: string) {
    const drone = await this.drones.findOne({ where: { id } });
    if (!drone) {
      throw new NotFoundException('El dron no existe.');
    }
    this.assertAssigned(user, drone.hubId);
    return drone;
  }

  private assertAssigned(user: User, hubId: string): void {
    if (!assignedHubIds(user).includes(hubId)) {
      throw new ForbiddenException('Esa central no está asignada a tu cuenta.');
    }
  }

  private assertNotInMission(drone: Drone): void {
    if (drone.status === DroneStatus.IN_MISSION) {
      throw new ConflictException(
        'No puedes cambiar el estado de un dron en misión.',
      );
    }
  }
}
