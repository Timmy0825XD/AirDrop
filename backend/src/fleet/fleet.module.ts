import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { GeofencesModule } from '../geofences/geofences.module';
import { Hub } from '../hubs/hub.entity';
import { HubsModule } from '../hubs/hubs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { Order } from '../orders/order.entity';
import { RoutingModule } from '../routing/routing.module';
import { Mission } from '../simulation/mission.entity';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { Drone } from './drone.entity';
import { DroneMaintenance } from './drone-maintenance.entity';
import { DroneModel } from './drone-model.entity';
import { DroneModelSeedService } from './drone-model-seed.service';
import { FleetController } from './fleet.controller';
import { FleetDashboardService } from './fleet-dashboard.service';
import { FleetFlightsService } from './fleet-flights.service';
import { FleetMapService } from './fleet-map.service';
import { FleetService } from './fleet.service';
import { MaintenanceSweepService } from './maintenance-sweep.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Drone,
      DroneMaintenance,
      DroneModel,
      Order,
      Mission,
      Hub,
    ]),
    AuthModule,
    GeofencesModule,
    HubsModule,
    NotificationsModule,
    RoutingModule,
    TelemetryModule,
  ],
  controllers: [FleetController],
  providers: [
    FleetService,
    FleetFlightsService,
    FleetMapService,
    FleetDashboardService,
    MaintenanceSweepService,
    DroneModelSeedService,
  ],
  exports: [FleetService],
})
export class FleetModule {}
