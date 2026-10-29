import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { RadarService } from './radar.service';

/** Vista web en vivo del ecosistema, solo para el administrador. */
@ApiTags('Radar')
@ApiBearerAuth()
@Controller('radar')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class RadarController {
  constructor(private readonly radar: RadarService) {}

  @Get('snapshot')
  snapshot() {
    return this.radar.snapshot();
  }

  @Get('hubs/:id')
  hub(@Param('id', new ParseUUIDPipe({ version: '4' })) id: string) {
    return this.radar.hubDetail(id);
  }

  @Get('flights/:orderId')
  flight(
    @Param('orderId', new ParseUUIDPipe({ version: '4' })) orderId: string,
  ) {
    return this.radar.flightDetail(orderId);
  }
}
