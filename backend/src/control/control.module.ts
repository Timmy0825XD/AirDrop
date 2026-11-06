import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Drone } from '../fleet/drone.entity';
import { GeofencesModule } from '../geofences/geofences.module';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { SimulationModule } from '../simulation/simulation.module';
import { WeatherModule } from '../weather/weather.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { ClockControlService } from './clock-control.service';
import { ConsoleEventsService } from './console-events.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ControlController } from './control.controller';
import { PendingAlertsService } from './pending-alerts.service';
import { ScenarioResetService } from './scenario-reset.service';
import { TimelineService } from './timeline.service';

/**
 * Consola de simulación (RF-31 a RF-40): reloj, línea de tiempo, alertas
 * pendientes y reinicio del escenario. Los eventos, los actores simulados y
 * el caos llegan en sus ramas.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Hub, Drone, Mission]),
    TelemetryModule,
    SimulationModule,
    WeatherModule,
    GeofencesModule,
  ],
  controllers: [ControlController],
  providers: [
    ClockControlService,
    ControlEnabledGuard,
    TimelineService,
    PendingAlertsService,
    ScenarioResetService,
    ConsoleEventsService,
  ],
})
export class ControlModule {}
