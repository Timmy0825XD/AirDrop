import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { UserRole } from '../common/enums/user-role.enum';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { User } from '../users/user.entity';
import { CreateHubDto } from './dto/create-hub.dto';
import { HubsService } from './hubs.service';

@Controller('hubs')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.DISPATCHER)
export class HubsController {
  constructor(private readonly hubsService: HubsService) {}

  @Post()
  create(@CurrentUser() user: User, @Body() dto: CreateHubDto) {
    return this.hubsService.create(user, dto);
  }

  @Get('me')
  me(@CurrentUser() user: User) {
    return this.hubsService.findMine(user);
  }
}
