import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { ClockControlService } from './clock-control.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ChangeClockDto } from './dto/change-clock.dto';

/** RU-32: consola de simulación de la web. Solo el administrador. */
@ApiTags('Control')
@ApiBearerAuth()
@Controller('control')
@UseGuards(ControlEnabledGuard, JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class ControlController {
  constructor(private readonly clock: ClockControlService) {}

  @Get('clock')
  getClock() {
    return this.clock.view();
  }

  @Put('clock')
  changeClock(@Body() dto: ChangeClockDto) {
    return this.clock.change(dto);
  }
}
