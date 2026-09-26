import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '../common/enums/user-role.enum';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { ListHubsQueryDto } from './dto/list-hubs-query.dto';
import { SetHubSuspensionDto } from './dto/set-hub-suspension.dto';
import { HubsService } from './hubs.service';

@Controller('hubs')
@UseGuards(JwtAuthGuard, RolesGuard)
export class HubsController {
  constructor(private readonly hubsService: HubsService) {}

  @Post()
  @Roles(UserRole.ADMIN)
  create(@CurrentUser() user: User, @Body() dto: CreateHubDto) {
    return this.hubsService.create(user, dto);
  }

  @Get('me')
  @Roles(UserRole.DISPATCHER)
  me(@CurrentUser() user: User) {
    return this.hubsService.findMine(user);
  }

  @Get()
  @Roles(UserRole.ADMIN, UserRole.FLEET_OPERATOR)
  list(@CurrentUser() user: User, @Query() query: ListHubsQueryDto) {
    if (user.role === UserRole.ADMIN) {
      return this.hubsService.listForAdmin(query.status);
    }
    return this.hubsService.listAssigned(user);
  }

  @Patch(':id/suspension')
  @Roles(UserRole.ADMIN)
  setSuspension(
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: SetHubSuspensionDto,
  ) {
    return this.hubsService.setSuspension(id, dto.suspended);
  }
}
