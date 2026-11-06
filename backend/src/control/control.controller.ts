import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { ClockControlService } from './clock-control.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ChangeClockDto } from './dto/change-clock.dto';
import { PendingAlertsService } from './pending-alerts.service';
import { ScenarioResetService } from './scenario-reset.service';
import { clampTimelineLimit } from './timeline.rules';
import { TimelineService } from './timeline.service';

/** RU-32: consola de simulación de la web. Solo el administrador. */
@ApiTags('Control')
@ApiBearerAuth()
@Controller('control')
@UseGuards(ControlEnabledGuard, JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class ControlController {
  constructor(
    private readonly clock: ClockControlService,
    private readonly timeline: TimelineService,
    private readonly alerts: PendingAlertsService,
    private readonly scenario: ScenarioResetService,
  ) {}

  @Get('clock')
  getClock() {
    return this.clock.view();
  }

  @Put('clock')
  changeClock(@Body() dto: ChangeClockDto) {
    return this.clock.change(dto);
  }

  /** RF-39: los últimos pasos del flujo, primero el más reciente. */
  @Get('timeline')
  getTimeline(@Query('limit') limit?: string) {
    return this.timeline.recent(clampTimelineLimit(limit));
  }

  /** RF-39: alertas de vuelo abiertas y dónde está cada dron. */
  @Get('alerts')
  getAlerts() {
    return this.alerts.list();
  }

  /** RF-40, CU-41: el escenario de la semilla, sin pedidos y en hora real. */
  @Post('reset')
  @HttpCode(200)
  reset(@CurrentUser() user: User) {
    return this.scenario.reset(user);
  }
}
