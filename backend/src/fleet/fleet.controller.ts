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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AnalyticsQueryDto } from '../analytics/dto/analytics-query.dto';
import { UserRole } from '../common/enums/user-role.enum';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { User } from '../users/user.entity';
import { CreateDroneDto } from './dto/create-drone.dto';
import { ListDronesQueryDto } from './dto/list-drones-query.dto';
import { ListFlightsQueryDto } from './dto/list-flights-query.dto';
import { RegisterMaintenanceDto } from './dto/register-maintenance.dto';
import { UpdateDroneStatusDto } from './dto/update-drone-status.dto';
import { FleetDashboardService } from './fleet-dashboard.service';
import { FleetFlightsService } from './fleet-flights.service';
import { FleetMapService } from './fleet-map.service';
import { FleetService } from './fleet.service';

@ApiTags('Flota')
@ApiBearerAuth()
@Controller('fleet')
@UseGuards(JwtAuthGuard, RolesGuard)
export class FleetController {
  constructor(
    private readonly fleetService: FleetService,
    private readonly fleetFlights: FleetFlightsService,
    private readonly fleetMap: FleetMapService,
    private readonly fleetDashboard: FleetDashboardService,
  ) {}

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
  async listDrones(
    @CurrentUser() user: User,
    @Query() query: ListDronesQueryDto,
  ) {
    const drones = await this.fleetService.listDrones(user, query.hubId);
    return this.fleetFlights.withActiveOrders(drones);
  }

  /** CU-19: vuelos en curso de las centrales del operador, con sus alertas. */
  @Get('flights')
  @Roles(UserRole.FLEET_OPERATOR)
  listFlights(@CurrentUser() user: User, @Query() query: ListFlightsQueryDto) {
    return this.fleetFlights.listFlights(user, query.hubId);
  }

  /** Mapa del operador: sus centrales, las geovallas y los vuelos en curso. */
  @Get('map')
  @Roles(UserRole.FLEET_OPERATOR)
  map(@CurrentUser() user: User, @Query() query: ListFlightsQueryDto) {
    return this.fleetMap.map(user, query.hubId);
  }

  /**
   * CU-20 del operador: uso, salud, incidentes y zonas de su flota en el
   * periodo (`from`/`to` en fechas de Colombia; por defecto, 30 días).
   */
  @Get('dashboard')
  @Roles(UserRole.FLEET_OPERATOR)
  dashboard(@CurrentUser() user: User, @Query() query: AnalyticsQueryDto) {
    return this.fleetDashboard.dashboard(user, query);
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

  /** CU-17: historial de taller del dron (el administrador solo lo lee). */
  @Get('drones/:id/maintenance')
  @Roles(UserRole.FLEET_OPERATOR, UserRole.ADMIN)
  listMaintenance(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.fleetService.listMaintenance(user, id);
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
