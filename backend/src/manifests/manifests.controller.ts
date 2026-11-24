import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { ManifestsService } from './manifests.service';

@ApiTags('Manifiestos')
@ApiBearerAuth()
@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ManifestsController {
  constructor(private readonly manifests: ManifestsService) {}

  /** RF-47: el manifiesto vigente del pedido y los anulados. */
  @Get(':id/manifest')
  @Roles(UserRole.DISPATCHER, UserRole.FLEET_OPERATOR, UserRole.ADMIN)
  forOrder(@CurrentUser() user: User, @Param('id', ParseUUIDPipe) id: string) {
    return this.manifests.forOrder(user, id);
  }
}
