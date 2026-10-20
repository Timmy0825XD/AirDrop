import {
  Controller,
  Get,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { TelemetryAccessService } from './telemetry-access.service';
import { TelemetryPublisher } from './telemetry.publisher';
import { presentTelemetry } from './telemetry.rules';

@ApiTags('Telemetría')
@ApiBearerAuth()
@Controller('telemetry')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TelemetryController {
  constructor(
    private readonly access: TelemetryAccessService,
    private readonly publisher: TelemetryPublisher,
  ) {}

  @Get('orders/:id')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER, UserRole.FLEET_OPERATOR)
  async snapshot(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    const access = await this.access.resolve(user, id);
    if (!access) {
      throw new NotFoundException('El pedido no existe.');
    }
    const flight = await this.publisher.readFlight(id);
    if (!flight) {
      throw new NotFoundException('Todavía no hay vuelo para este pedido.');
    }
    return presentTelemetry(flight, access.view);
  }
}
