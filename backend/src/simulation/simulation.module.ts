import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Drone } from '../fleet/drone.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { Order } from '../orders/order.entity';
import { RoutingModule } from '../routing/routing.module';
import { WeatherModule } from '../weather/weather.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { FlightClockService } from './flight-clock.service';
import { FlightIncident } from './flight-incident.entity';
import { FlightIncidentsService } from './flight-incidents.service';
import { Mission } from './mission.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Drone, Mission, FlightIncident]),
    RoutingModule,
    TelemetryModule,
    NotificationsModule,
    WeatherModule,
  ],
  providers: [FlightClockService, FlightIncidentsService],
  exports: [FlightClockService, FlightIncidentsService],
})
export class SimulationModule {}
