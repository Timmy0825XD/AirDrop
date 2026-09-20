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
import { CreateDroneDto } from './dto/create-drone.dto';
import { ListDronesQueryDto } from './dto/list-drones-query.dto';
import { RegisterMaintenanceDto } from './dto/register-maintenance.dto';
import { UpdateDroneStatusDto } from './dto/update-drone-status.dto';
import { FleetService } from './fleet.service';

@Controller('fleet')
@UseGuards(JwtAuthGuard, RolesGuard)
export class FleetController {
  constructor(private readonly fleetService: FleetService) {}

  @Get('models')
  @Roles(UserRole.FLEET_OPERATOR, UserRole.ADMIN)
  listModels() {
    return this.fleetService.listModels();
  }

  @Post('drones')
  @Roles(UserRole.FLEET_OPERATOR)
  createDrone(@CurrentUser() user: User, @Body() dto: CreateDroneDto) {
    return this.fleetService.createDrone(user, dto);
  }

  @Get('drones')
  @Roles(UserRole.FLEET_OPERATOR, UserRole.ADMIN)
  listDrones(@CurrentUser() user: User, @Query() query: ListDronesQueryDto) {
    return this.fleetService.listDrones(user, query.hubId);
  }

  @Patch('drones/:id/status')
  @Roles(UserRole.FLEET_OPERATOR)
  updateStatus(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: UpdateDroneStatusDto,
  ) {
    return this.fleetService.updateStatus(user, id, dto);
  }

  @Post('drones/:id/maintenance')
  @Roles(UserRole.FLEET_OPERATOR)
  registerMaintenance(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: RegisterMaintenanceDto,
  ) {
    return this.fleetService.registerMaintenance(user, id, dto);
  }
}
