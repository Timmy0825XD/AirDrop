import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { HubsModule } from '../hubs/hubs.module';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { Drone } from './drone.entity';
import { DroneModel } from './drone-model.entity';
import { DroneModelSeedService } from './drone-model-seed.service';
import { FleetController } from './fleet.controller';
import { FleetFlightsService } from './fleet-flights.service';
import { FleetService } from './fleet.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Drone, DroneModel, Order, Mission]),
    AuthModule,
    HubsModule,
    TelemetryModule,
  ],
  controllers: [FleetController],
  providers: [FleetService, FleetFlightsService, DroneModelSeedService],
  exports: [FleetService],
})
export class FleetModule {}
