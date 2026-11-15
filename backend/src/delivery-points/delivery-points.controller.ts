import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
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
import { DeliveryPointsService } from './delivery-points.service';
import { CoverageQueryDto } from './dto/coverage-query.dto';
import { SetDeliveryPointActiveDto } from './dto/set-active.dto';

@ApiTags('Puntos de entrega')
@ApiBearerAuth()
@Controller('delivery-points')
@UseGuards(JwtAuthGuard, RolesGuard)
export class DeliveryPointsController {
  constructor(private readonly points: DeliveryPointsService) {}

  /**
   * RU-02 y RF-45: con el GPS, el punto activo más cercano y la lista por
   * distancia; si el solicitante está en la ciudad o no hay punto, el motivo
   * y, con `medicationName`, la alternativa terrestre. El administrador ve
   * también los inactivos.
   */
  @Get()
  coverage(@CurrentUser() user: User, @Query() query: CoverageQueryDto) {
    return this.points.coverage(user, query);
  }

  /** RF-45: activar o desactivar un punto. */
  @Patch(':id')
  @Roles(UserRole.ADMIN)
  setActive(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SetDeliveryPointActiveDto,
  ) {
    return this.points.setActive(id, dto.active);
  }
}
