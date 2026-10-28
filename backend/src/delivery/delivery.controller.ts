import {
  Body,
  Controller,
  Get,
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
import { ValidateDeliveryCodeDto } from './dto/validate-delivery-code.dto';
import { DeliveryService } from './delivery.service';

@ApiTags('Entrega')
@ApiBearerAuth()
@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class DeliveryController {
  constructor(private readonly deliveryService: DeliveryService) {}

  @Get(':id/delivery-code')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  show(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.deliveryService.show(user, id);
  }

  @Post(':id/delivery-code/validate')
  @HttpCode(200)
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  validate(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: ValidateDeliveryCodeDto,
  ) {
    return this.deliveryService.validate(user, id, dto);
  }
}
