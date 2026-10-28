import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { AnalyticsService } from './analytics.service';
import { AnalyticsQueryDto } from './dto/analytics-query.dto';

/** Tablero del administrador (RF-26, HU-37, HU-38). No abre fórmulas. */
@ApiTags('Métricas')
@ApiBearerAuth()
@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AnalyticsController {
  constructor(private readonly analytics: AnalyticsService) {}

  @Get('kpis')
  kpis(@Query() query: AnalyticsQueryDto) {
    return this.analytics.kpis(query);
  }

  @Get('demand')
  demand(@Query() query: AnalyticsQueryDto) {
    return this.analytics.demand(query);
  }

  @Get('hubs')
  hubs(@Query() query: AnalyticsQueryDto) {
    return this.analytics.hubs(query);
  }
}
