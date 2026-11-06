import { Module } from '@nestjs/common';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { ClockControlService } from './clock-control.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ControlController } from './control.controller';

/**
 * Consola de simulación (RF-31 a RF-40). Por ahora, el reloj; los eventos,
 * los actores simulados, el caos y el reinicio llegan en sus ramas.
 */
@Module({
  imports: [TelemetryModule],
  controllers: [ControlController],
  providers: [ClockControlService, ControlEnabledGuard],
})
export class ControlModule {}
