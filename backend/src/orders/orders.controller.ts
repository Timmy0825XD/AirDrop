import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { CreateHubEmergencyDto } from './dto/create-hub-emergency.dto';
import { RejectOrderDto } from './dto/reject-order.dto';
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

  @Get('queue')
  @Roles(UserRole.DISPATCHER)
  queue(@CurrentUser() user: User) {
    return this.ordersService.listQueue(user);
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

  @Get(':id/prescription')
  @Roles(UserRole.DISPATCHER)
  async prescription(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    const image = await this.ordersService.readPrescription(user, id);
    return new StreamableFile(image.content, {
      type: image.mime,
      disposition: 'inline',
    });
  }

  @Get(':id')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  findOne(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.ordersService.findOne(user, id);
  }

  @Post(':id/reject')
  @Roles(UserRole.DISPATCHER)
  reject(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: RejectOrderDto,
  ) {
    return this.ordersService.reject(user, id, dto);
  }
}
