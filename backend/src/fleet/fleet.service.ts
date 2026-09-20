import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateDroneDto } from './dto/create-drone.dto';
import { RegisterMaintenanceDto } from './dto/register-maintenance.dto';
import { UpdateDroneStatusDto } from './dto/update-drone-status.dto';
import { Drone } from './drone.entity';
import { DroneModel } from './drone-model.entity';

@Injectable()
export class FleetService {
  constructor(
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    @InjectRepository(DroneModel)
    private readonly models: Repository<DroneModel>,
    private readonly hubsService: HubsService,
  ) {}

  async listModels() {
    const rows = await this.models.find({ order: { name: 'ASC' } });
    return rows.map((row) => this.toPublicModel(row));
  }

  async createDrone(user: User, dto: CreateDroneDto) {
    this.assertActiveOperator(user);
    const model = await this.models.findOne({
      where: { id: dto.droneModelId },
    });
    if (!model) {
      throw new NotFoundException('El modelo de dron no existe.');
    }
    await this.hubsService.requireApproved(dto.hubId);
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

  async listDrones(user: User, hubId: string) {
    this.assertActiveOperator(user);
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

  async updateStatus(user: User, id: string, dto: UpdateDroneStatusDto) {
    const drone = await this.requireActiveOperatorDrone(user, id);
    this.assertNotInMission(drone);
    drone.status = dto.status;
    if (dto.status === DroneStatus.AVAILABLE) {
      drone.maintenanceReason = null;
      drone.maintenanceUntil = null;
    } else {
      drone.maintenanceReason = dto.reason?.trim() || drone.maintenanceReason;
      drone.maintenanceUntil = dto.estimatedEndDate ?? drone.maintenanceUntil;
    }
    const saved = await this.drones.save(drone);
    return this.toPublicDrone(saved);
  }

  async registerMaintenance(
    user: User,
    id: string,
    dto: RegisterMaintenanceDto,
  ) {
    const drone = await this.requireActiveOperatorDrone(user, id);
    this.assertNotInMission(drone);
    drone.status = DroneStatus.OUT_OF_SERVICE;
    drone.maintenanceReason = dto.reason.trim();
    drone.maintenanceUntil = dto.estimatedEndDate;
    const saved = await this.drones.save(drone);
    return this.toPublicDrone(saved);
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
      createdAt: drone.createdAt,
    };
  }

  private async requireActiveOperatorDrone(user: User, id: string) {
    this.assertActiveOperator(user);
    const drone = await this.drones.findOne({ where: { id } });
    if (!drone) {
      throw new NotFoundException('El dron no existe.');
    }
    return drone;
  }

  private assertNotInMission(drone: Drone): void {
    if (drone.status === DroneStatus.IN_MISSION) {
      throw new ConflictException(
        'No puedes cambiar el estado de un dron en misión.',
      );
    }
  }

  private assertActiveOperator(user: User): void {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar la flota.',
      );
    }
  }
}
