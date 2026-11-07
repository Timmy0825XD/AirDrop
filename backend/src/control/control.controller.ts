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
import { ChaosService } from './chaos.service';
import { ChangeActorsDto } from './dto/change-actors.dto';
import { ChangeChaosDto } from './dto/change-chaos.dto';
import { ChangeClockDto } from './dto/change-clock.dto';
import { CreateSurgeDto } from './dto/create-surge.dto';
import { GenerateOrderDto } from './dto/generate-order.dto';
import { OrderGeneratorService } from './order-generator.service';
import { SimActorsService } from './sim-actors.service';
import { CreateTemporaryGeofenceDto } from './dto/create-temporary-geofence.dto';
import { CreateWeatherDto } from './dto/create-weather.dto';
import { LaunchIncidentDto } from './dto/launch-incident.dto';
import { StartHubOutageDto } from './dto/start-hub-outage.dto';
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
    private readonly actors: SimActorsService,
    private readonly generator: OrderGeneratorService,
    private readonly chaos: ChaosService,
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

  /** RF-36: las centrales sin energía ahora y hasta cuándo. */
  @Get('hubs/outages')
  getOutages() {
    return this.events.listOutages();
  }

  /** RF-36, CU-45: deja una central sin energía por un tiempo. */
  @Post('hubs/:hubId/outage')
  startOutage(
    @Param('hubId', new ParseUUIDPipe({ version: '4' })) hubId: string,
    @Body() dto: StartHubOutageDto,
  ) {
    return this.events.startOutage(hubId, dto.durationMin);
  }

  /** Devuelve la energía antes de tiempo. */
  @Delete('hubs/:hubId/outage')
  endOutage(
    @Param('hubId', new ParseUUIDPipe({ version: '4' })) hubId: string,
  ) {
    return this.events.endOutage(hubId);
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

  /** RF-37: qué actores simulados están encendidos. */
  @Get('actors')
  getActors() {
    return this.actors.view();
  }

  /** RF-37, CU-39: enciende o apaga el despachador automático y el flujo de pedidos. */
  @Put('actors')
  changeActors(@Body() dto: ChangeActorsDto) {
    return this.actors.change(dto);
  }

  /** CU-39: el generador crea una urgencia o un programado de un solicitante simulado. */
  @Post('actors/orders')
  generateOrder(@Body() dto: GenerateOrderDto) {
    return this.generator.generate(dto.kind);
  }

  /** RF-36: pico de urgencias en una zona del mapa. */
  @Post('actors/surge')
  createSurge(@Body() dto: CreateSurgeDto) {
    return this.generator.surge(
      { latitude: dto.latitude, longitude: dto.longitude },
      dto.radiusKm,
      dto.count,
    );
  }

  /** RF-38: si el modo caos está encendido y con qué intensidad. */
  @Get('chaos')
  getChaos() {
    return this.chaos.view();
  }

  /** RF-38, CU-40: enciende o apaga el caos, o cambia su intensidad. */
  @Put('chaos')
  changeChaos(@CurrentUser() user: User, @Body() dto: ChangeChaosDto) {
    return this.chaos.change(user.id, dto);
  }

  /** RF-40, CU-41: el escenario de la semilla, sin pedidos y en hora real. */
  @Post('reset')
  @HttpCode(200)
  reset(@CurrentUser() user: User) {
    return this.scenario.reset(user);
  }
}
