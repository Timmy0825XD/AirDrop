import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { ClockControlService } from './clock-control.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ControlController } from './control.controller';
import { PendingAlertsService } from './pending-alerts.service';
import { TimelineService } from './timeline.service';

/**
 * Consola de simulación (RF-31 a RF-40): reloj, línea de tiempo y alertas
 * pendientes. Los eventos, los actores simulados, el caos y el reinicio
 * llegan en sus ramas.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Hub, Drone, Mission]),
    TelemetryModule,
  ],
  controllers: [ControlController],
  providers: [
    ClockControlService,
    ControlEnabledGuard,
    TimelineService,
    PendingAlertsService,
  ],
})
export class ControlModule {}
