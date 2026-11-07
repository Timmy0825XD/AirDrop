import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DecisionModule } from '../decision/decision.module';
import { DeliveryModule } from '../delivery/delivery.module';
import { Drone } from '../fleet/drone.entity';
import { GeofencesModule } from '../geofences/geofences.module';
import { HubsModule } from '../hubs/hubs.module';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import { OrdersModule } from '../orders/orders.module';
import { User } from '../users/user.entity';
import { Mission } from '../simulation/mission.entity';
import { SimulationModule } from '../simulation/simulation.module';
import { WeatherModule } from '../weather/weather.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { AutoDispatcherService } from './auto-dispatcher.service';
import { ClockControlService } from './clock-control.service';
import { ConsoleEventsService } from './console-events.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ControlController } from './control.controller';
import { PendingAlertsService } from './pending-alerts.service';
import { OrderGeneratorService } from './order-generator.service';
import { ScenarioResetService } from './scenario-reset.service';
import { SimActorsService } from './sim-actors.service';
import { SimulatedReceiverService } from './simulated-receiver.service';
import { TimelineService } from './timeline.service';

/**
 * Consola de simulación (RF-31 a RF-40): reloj, línea de tiempo, alertas
 * pendientes, eventos, actores simulados y reinicio del escenario. Los
 * actores usan los servicios de Orders, Decision y Delivery, como una persona.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Hub, Drone, Mission, User]),
    TelemetryModule,
    SimulationModule,
    WeatherModule,
    GeofencesModule,
    HubsModule,
    OrdersModule,
    DecisionModule,
    DeliveryModule,
  ],
  controllers: [ControlController],
  providers: [
    ClockControlService,
    ControlEnabledGuard,
    TimelineService,
    PendingAlertsService,
    ScenarioResetService,
    ConsoleEventsService,
    SimActorsService,
    AutoDispatcherService,
    OrderGeneratorService,
    SimulatedReceiverService,
  ],
})
export class ControlModule {}
