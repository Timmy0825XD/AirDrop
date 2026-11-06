import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { FlightIncidentsService } from '../simulation/flight-incidents.service';
import { ClockControlService } from './clock-control.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { ConsoleEventsService } from './console-events.service';
import { ChangeClockDto } from './dto/change-clock.dto';
import { CreateTemporaryGeofenceDto } from './dto/create-temporary-geofence.dto';
import { CreateWeatherDto } from './dto/create-weather.dto';
import { LaunchIncidentDto } from './dto/launch-incident.dto';
import { PendingAlertsService } from './pending-alerts.service';
import { ScenarioResetService } from './scenario-reset.service';
import { clampTimelineLimit } from './timeline.rules';
import { TimelineService } from './timeline.service';

/** RU-32: consola de simulación de la web. Solo el administrador. */
@ApiTags('Control')
@ApiBearerAuth()
@Controller('control')
@UseGuards(ControlEnabledGuard, JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class ControlController {
  constructor(
    private readonly clock: ClockControlService,
    private readonly timeline: TimelineService,
    private readonly alerts: PendingAlertsService,
    private readonly scenario: ScenarioResetService,
    private readonly events: ConsoleEventsService,
    private readonly incidents: FlightIncidentsService,
  ) {}

  @Get('clock')
  getClock() {
    return this.clock.view();
  }

  @Put('clock')
  changeClock(@Body() dto: ChangeClockDto) {
    return this.clock.change(dto);
  }

  /** RF-39: los últimos pasos del flujo, primero el más reciente. */
  @Get('timeline')
  getTimeline(@Query('limit') limit?: string) {
    return this.timeline.recent(clampTimelineLimit(limit));
  }

  /** RF-39: alertas de vuelo abiertas y dónde está cada dron. */
  @Get('alerts')
  getAlerts() {
    return this.alerts.list();
  }

  /**
   * RF-34: los últimos incidentes en vuelo, con su protocolo, en qué quedó y
   * dónde bajó el dron si aterrizó de emergencia.
   */
  @Get('incidents')
  getIncidents(@Query('limit') limit?: string) {
    return this.incidents.recent(clampTimelineLimit(limit));
  }

  /**
   * RF-34, CU-38: falla, choque o pérdida sobre un dron en vuelo. El
   * protocolo lo eligen las reglas; la respuesta trae cuál.
   */
  @Post('drones/:droneId/incidents')
  launchIncident(
    @Param('droneId', new ParseUUIDPipe({ version: '4' })) droneId: string,
    @Body() dto: LaunchIncidentDto,
  ) {
    return this.events.launchIncident(droneId, dto.kind);
  }

  /** RF-32: las celdas de clima que rigen ahora. */
  @Get('weather')
  getWeather() {
    return this.events.listWeather();
  }

  /** RF-32, CU-38: viento, lluvia o tormenta sobre una zona del mapa. */
  @Post('weather')
  createWeather(@CurrentUser() user: User, @Body() dto: CreateWeatherDto) {
    return this.events.createWeather(user.id, dto);
  }

  /** Corta una celda de clima antes de tiempo. */
  @Delete('weather/:id')
  endWeather(@Param('id', new ParseUUIDPipe({ version: '4' })) id: string) {
    return this.events.endWeather(id);
  }

  /** RF-36: las geovallas temporales que rigen ahora. */
  @Get('geofences')
  getGeofences() {
    return this.events.listGeofences();
  }

  /** RF-36, CU-38: una geovalla que vence sola (por ejemplo, un evento aéreo). */
  @Post('geofences')
  createGeofence(
    @CurrentUser() user: User,
    @Body() dto: CreateTemporaryGeofenceDto,
  ) {
    return this.events.createGeofence(user.id, dto);
  }

  /** Levanta una geovalla temporal antes de que venza. Las del operador no. */
  @Delete('geofences/:id')
  endGeofence(@Param('id', new ParseUUIDPipe({ version: '4' })) id: string) {
    return this.events.endGeofence(id);
  }

  /** RF-40, CU-41: el escenario de la semilla, sin pedidos y en hora real. */
  @Post('reset')
  @HttpCode(200)
  reset(@CurrentUser() user: User) {
    return this.scenario.reset(user);
  }
}
