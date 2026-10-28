import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { RescheduleOccurrenceDto } from './dto/reschedule-occurrence.dto';
import { PlanOccurrencesService } from './plan-occurrences.service';

/** RU-30: quien recibe confirma, omite o mueve una entrega de su plan. */
@ApiTags('Pedidos')
@ApiBearerAuth()
@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
export class PlanOccurrencesController {
  constructor(private readonly occurrences: PlanOccurrencesService) {}

  @Post(':id/confirm')
  @HttpCode(200)
  confirm(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.occurrences.confirm(user, id);
  }

  @Post(':id/skip')
  @HttpCode(200)
  skip(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.occurrences.skip(user, id);
  }

  @Post(':id/reschedule')
  @HttpCode(200)
  reschedule(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: RescheduleOccurrenceDto,
  ) {
    return this.occurrences.reschedule(user, id, dto);
  }
}
