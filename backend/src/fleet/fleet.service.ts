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
    const hub = await this.hubsService.findById(dto.hubId);
    if (!hub) {
      throw new NotFoundException('La central no existe.');
    }
    const duplicate = await this.drones.findOne({
      where: { identifier: dto.identifier },
    });
    if (duplicate) {
      throw new ConflictException('Ya existe un dron con este identificador.');
    }
    const drone = this.drones.create({
      identifier: dto.identifier,
      droneModelId: model.id,
      hubId: hub.id,
      status: DroneStatus.AVAILABLE,
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
      createdAt: drone.createdAt,
    };
  }

  private assertActiveOperator(user: User): void {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar la flota.',
      );
    }
  }
}
