import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { HubsModule } from '../hubs/hubs.module';
import { Drone } from './drone.entity';
import { DroneModel } from './drone-model.entity';
import { DroneModelSeedService } from './drone-model-seed.service';
import { FleetController } from './fleet.controller';
import { FleetService } from './fleet.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Drone, DroneModel]),
    AuthModule,
    HubsModule,
  ],
  controllers: [FleetController],
  providers: [FleetService, DroneModelSeedService],
  exports: [FleetService],
})
export class FleetModule {}
