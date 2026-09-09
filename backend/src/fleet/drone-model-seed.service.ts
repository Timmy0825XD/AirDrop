import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DroneModel } from './drone-model.entity';

export const WINGCOPTER_198_CODE = 'wingcopter_198';

@Injectable()
export class DroneModelSeedService implements OnModuleInit {
  private readonly logger = new Logger(DroneModelSeedService.name);

  constructor(
    @InjectRepository(DroneModel)
    private readonly models: Repository<DroneModel>,
  ) {}

  async onModuleInit(): Promise<void> {
    const existing = await this.models.findOne({
      where: { code: WINGCOPTER_198_CODE },
    });
    if (existing) {
      return;
    }
    await this.models.save(
      this.models.create({
        code: WINGCOPTER_198_CODE,
        name: 'Wingcopter 198',
        maxSpeedKmh: 150,
        maxPayloadKg: 6,
        maxRangeKm: 110,
      }),
    );
    this.logger.log('Modelo Wingcopter 198 creado');
  }
}
