import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import {
  ChangeReasonDto,
  CreateLegalZoneDto,
  UpdateLegalZoneDto,
} from './dto/legal-zone.dto';
import { LegalZonesService } from './legal-zones.service';

/** RU-36 y CU-52: solo el administrador mantiene las zonas legales. */
@ApiTags('Geovallas')
@ApiBearerAuth()
@Controller('geofences/legal')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class LegalZonesController {
  constructor(private readonly legalZones: LegalZonesService) {}

  @Post()
  create(@CurrentUser() user: User, @Body() dto: CreateLegalZoneDto) {
    return this.legalZones.create(user, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: UpdateLegalZoneDto,
  ) {
    return this.legalZones.update(user, id, dto);
  }

  @Post(':id/deactivate')
  @HttpCode(200)
  deactivate(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: ChangeReasonDto,
  ) {
    return this.legalZones.deactivate(user, id, dto.reason);
  }

  @Post(':id/reactivate')
  @HttpCode(200)
  reactivate(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: ChangeReasonDto,
  ) {
    return this.legalZones.reactivate(user, id, dto.reason);
  }
}
