import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { CreateHubEmergencyDto } from './dto/create-hub-emergency.dto';
import { OrdersService } from './orders.service';

@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get('catalog')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  catalog(@CurrentUser() user: User, @Query() query: CatalogQueryDto) {
    return this.ordersService.catalog(user, query);
  }

  @Get('origin-hubs')
  @Roles(UserRole.DISPATCHER)
  originHubs(@CurrentUser() user: User) {
    return this.ordersService.listOriginHubs(user);
  }

  @Post('emergencies')
  @Roles(UserRole.REQUESTER)
  createEmergency(@CurrentUser() user: User, @Body() dto: CreateEmergencyDto) {
    return this.ordersService.createEmergency(user, dto);
  }

  @Post('hub-emergencies')
  @Roles(UserRole.DISPATCHER)
  createHubEmergency(
    @CurrentUser() user: User,
    @Body() dto: CreateHubEmergencyDto,
  ) {
    return this.ordersService.createHubEmergency(user, dto);
  }
}
