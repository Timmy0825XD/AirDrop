import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Drone } from '../fleet/drone.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { Order } from '../orders/order.entity';
import { RoutingModule } from '../routing/routing.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { FlightClockService } from './flight-clock.service';
import { Mission } from './mission.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Drone, Mission]),
    RoutingModule,
    TelemetryModule,
    NotificationsModule,
  ],
  providers: [FlightClockService],
  exports: [FlightClockService],
})
export class SimulationModule {}
