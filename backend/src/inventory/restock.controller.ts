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
import { ReturnCheckDto } from './dto/return-check.dto';
import { RestockService } from './restock.service';

/** Revisión de un paquete devuelto, sobre la ruta del pedido. */
@ApiTags('Inventario')
@ApiBearerAuth()
@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RestockController {
  constructor(private readonly restockService: RestockService) {}

  /** Paquete devuelto: reingresa al inventario o queda en cuarentena. */
  @Post(':id/return-check')
  @HttpCode(200)
  @Roles(UserRole.DISPATCHER)
  returnCheck(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: ReturnCheckDto,
  ) {
    return this.restockService.checkReturn(user, id, dto.packagingIntact);
  }
}
