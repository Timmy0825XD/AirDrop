import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { GeofenceClass } from '../common/enums/geofence-class.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { CreateGeofenceDto } from './dto/create-geofence.dto';
import { UpdateGeofenceDto } from './dto/update-geofence.dto';
import { GeofencesService } from './geofences.service';
import { LegalZonesService } from './legal-zones.service';

export class GeofenceQueryDto {
  @IsOptional()
  @IsEnum(GeofenceClass, { message: 'La clase no es válida.' })
  class?: GeofenceClass;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'active va en true o false.' })
  active?: boolean;
}

/**
 * RU-19: el operador y el admin ven todas las geovallas con su ficha. Las
 * operativas las gestiona el operador; las legales, el admin
 * (`LegalZonesController`).
 */
@ApiTags('Geovallas')
@ApiBearerAuth()
@Controller('geofences')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.FLEET_OPERATOR, UserRole.ADMIN)
export class GeofencesController {
  constructor(
    private readonly geofencesService: GeofencesService,
    private readonly legalZones: LegalZonesService,
  ) {}

  @Get()
  catalog(@Query() query: GeofenceQueryDto) {
    return this.geofencesService.catalog(query);
  }

  @Get(':id')
  findOne(@Param('id', new ParseUUIDPipe({ version: '4' })) id: string) {
    return this.geofencesService.findOne(id);
  }

  /** RU-36: el historial de una zona legal. */
  @Get(':id/changes')
  changes(@Param('id', new ParseUUIDPipe({ version: '4' })) id: string) {
    return this.legalZones.history(id);
  }

  @Post()
  @Roles(UserRole.FLEET_OPERATOR)
  create(@CurrentUser() user: User, @Body() dto: CreateGeofenceDto) {
    return this.geofencesService.create(user, dto);
  }

  @Patch(':id')
  @Roles(UserRole.FLEET_OPERATOR)
  update(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: UpdateGeofenceDto,
  ) {
    return this.geofencesService.update(user, id, dto);
  }

  @Delete(':id')
  @Roles(UserRole.FLEET_OPERATOR)
  @HttpCode(204)
  remove(@Param('id', new ParseUUIDPipe({ version: '4' })) id: string) {
    return this.geofencesService.remove(id);
  }
}
