import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Patch,
  ParseUUIDPipe,
  Post,
  Query,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthorizeOrderDto } from '../decision/dto/authorize-order.dto';
import { DecisionService } from '../decision/decision.service';
import { User } from '../users/user.entity';
import { AgendaQueryDto } from './dto/agenda-query.dto';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { CreateHubEmergencyDto } from './dto/create-hub-emergency.dto';
import { CreateHubPlanDto } from './dto/create-hub-plan.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { HistoryQueryDto } from './dto/history-query.dto';
import { PreviewPlanDto, UpdatePlanScheduleDto } from './dto/plan-schedule.dto';
import { RejectOrderDto } from './dto/reject-order.dto';
import { OrdersService } from './orders.service';
import { PlanAgendaService } from './plan-agenda.service';

@ApiTags('Pedidos')
@ApiBearerAuth()
@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly decisionService: DecisionService,
    private readonly agenda: PlanAgendaService,
  ) {}

  @Get('catalog')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  catalog(@CurrentUser() user: User, @Query() query: CatalogQueryDto) {
    return this.ordersService.catalog(user, query);
  }

  @Get('mine')
  @Roles(UserRole.REQUESTER)
  async mine(@CurrentUser() user: User) {
    const rows = await this.ordersService.listMine(user);
    return this.decisionService.attachAssignments(rows);
  }

  @Get('incoming')
  @Roles(UserRole.DISPATCHER)
  async incoming(@CurrentUser() user: User) {
    const rows = await this.ordersService.listIncoming(user);
    return this.decisionService.attachAssignments(rows);
  }

  /** HU-36: misiones cerradas que despachó la central. */
  @Get('history')
  @Roles(UserRole.DISPATCHER)
  history(@CurrentUser() user: User, @Query() query: HistoryQueryDto) {
    return this.ordersService.listHistory(user, query);
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

  @Get('scheduled')
  @Roles(UserRole.DISPATCHER)
  scheduled(@CurrentUser() user: User) {
    return this.ordersService.listScheduled(user);
  }

  /** RU-30: el día del despachador, agrupado por franja. */
  @Get('agenda')
  @Roles(UserRole.DISPATCHER)
  agendaFor(@CurrentUser() user: User, @Query() query: AgendaQueryDto) {
    return this.agenda.list(user, query.date);
  }

  @Get('pending-load')
  @Roles(UserRole.DISPATCHER)
  pendingLoad(@CurrentUser() user: User) {
    return this.decisionService.listPendingLoad(user);
  }

  @Get('in-flight')
  @Roles(UserRole.DISPATCHER)
  inFlight(@CurrentUser() user: User) {
    return this.decisionService.listInFlight(user);
  }

  @Post('plans')
  @Roles(UserRole.REQUESTER)
  async createPlan(@CurrentUser() user: User, @Body() dto: CreatePlanDto) {
    return this.agenda.withCapacity(await this.ordersService.createPlan(user, dto));
  }

  @Post('hub-plans')
  @Roles(UserRole.DISPATCHER)
  async createHubPlan(@CurrentUser() user: User, @Body() dto: CreateHubPlanDto) {
    return this.agenda.withCapacity(
      await this.ordersService.createHubPlan(user, dto),
    );
  }

  /** RU-30: las fechas y franjas que dejaría un calendario, sin crear nada. */
  @Post('plans/preview')
  @HttpCode(200)
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  previewPlan(@CurrentUser() user: User, @Body() dto: PreviewPlanDto) {
    return this.ordersService.previewPlan(user, dto);
  }

  @Patch('plans/:id/schedule')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  async updatePlanSchedule(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: UpdatePlanScheduleDto,
  ) {
    return this.agenda.withCapacity(
      await this.ordersService.updatePlanSchedule(user, id, dto),
    );
  }

  @Get('plans')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  plans(@CurrentUser() user: User) {
    return this.ordersService.listPlans(user);
  }

  @Get('plans/:id')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  findPlan(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.ordersService.findPlan(user, id);
  }

  @Post('plans/:id/extend')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  extendPlan(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.ordersService.extendPlan(user, id);
  }

  @Post('plans/:id/pause')
  @HttpCode(200)
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  pausePlan(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.ordersService.setPlanPaused(user, id, true);
  }

  @Post('plans/:id/resume')
  @HttpCode(200)
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  resumePlan(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.ordersService.setPlanPaused(user, id, false);
  }

  @Post('plans/:id/cancel')
  @Roles(UserRole.REQUESTER, UserRole.DISPATCHER)
  cancelPlan(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.ordersService.cancelPlan(user, id);
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
  async findOne(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    const order = await this.ordersService.findOne(user, id);
    const [withAssignment] = await this.decisionService.attachAssignments([
      order,
    ]);
    return withAssignment;
  }

  @Post(':id/authorize')
  @Roles(UserRole.DISPATCHER)
  authorize(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: AuthorizeOrderDto,
  ) {
    return this.decisionService.authorize(user, id, dto);
  }

  @Post(':id/confirm-load')
  @Roles(UserRole.DISPATCHER)
  confirmLoad(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.decisionService.confirmLoad(user, id);
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
