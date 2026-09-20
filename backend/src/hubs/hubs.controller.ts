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
import { DecideHubDto } from './dto/decide-hub.dto';
import { ListHubsQueryDto } from './dto/list-hubs-query.dto';
import { HubsService } from './hubs.service';

@Controller('hubs')
@UseGuards(JwtAuthGuard, RolesGuard)
export class HubsController {
  constructor(private readonly hubsService: HubsService) {}

  @Post()
  @Roles(UserRole.DISPATCHER)
  create(@CurrentUser() user: User, @Body() dto: CreateHubDto) {
    return this.hubsService.create(user, dto);
  }

  @Get('me')
  @Roles(UserRole.DISPATCHER)
  me(@CurrentUser() user: User) {
    return this.hubsService.findMine(user);
  }

  @Get()
  @Roles(UserRole.ADMIN)
  list(@Query() query: ListHubsQueryDto) {
    return this.hubsService.listForAdmin(query.status);
  }

  @Patch(':id/decision')
  @Roles(UserRole.ADMIN)
  decide(
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: DecideHubDto,
  ) {
    return this.hubsService.decide(id, dto);
  }
}
