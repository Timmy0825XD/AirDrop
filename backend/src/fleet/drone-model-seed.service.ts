import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Drone } from './drone.entity';
import { DroneModel } from './drone-model.entity';
import { DRONE_TYPES } from './drone-types';

/** El modelo comercial de antes de la flota propia (RF-49). */
export const RETIRED_MODEL_CODE = 'wingcopter_198';

/** Código del Garza: hereda los drones del modelo retirado. */
export const BALANCED_MODEL_CODE = 'balanced';

/**
 * RF-49: al arrancar deja los tres tipos con sus cifras de
 * `drone-types.ts` (crea o corrige). Si queda el modelo comercial de antes,
 * sus drones pasan a Garza y el modelo se borra.
 */
@Injectable()
export class DroneModelSeedService implements OnModuleInit {
  private readonly logger = new Logger(DroneModelSeedService.name);

  constructor(
    @InjectRepository(DroneModel)
    private readonly models: Repository<DroneModel>,
  ) {}

  async onModuleInit(): Promise<void> {
    for (const spec of DRONE_TYPES) {
      const existing = await this.models.findOne({
        where: { code: spec.code },
      });
      await this.models.save(
        existing ? this.models.merge(existing, spec) : this.models.create(spec),
      );
    }
    await this.retireOldModel();
  }

  private async retireOldModel(): Promise<void> {
    const retired = await this.models.findOne({
      where: { code: RETIRED_MODEL_CODE },
    });
    if (!retired) {
      return;
    }
    const balanced = await this.models.findOneOrFail({
      where: { code: BALANCED_MODEL_CODE },
    });
    await this.models.manager.update(
      Drone,
      { droneModelId: retired.id },
      { droneModelId: balanced.id },
    );
    await this.models.delete({ id: retired.id });
    this.logger.log('Modelo comercial retirado: sus drones pasan a Garza');
  }
}
