import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
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
import {
  AcceptPolicyDto,
  AccessLogQueryDto,
  ConfirmWithPasswordDto,
} from './dto/privacy.dto';
import { PrivacyService } from './privacy.service';

@ApiTags('Datos personales')
@Controller('privacy')
export class PrivacyController {
  constructor(private readonly privacy: PrivacyService) {}

  /** RF-50: la política vigente, sin sesión (se lee antes de registrarse). */
  @Get('policy')
  policy() {
    return this.privacy.policy();
  }

  /** CU-46: sus datos y la versión de la política que aceptó. */
  @Get('me')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: User) {
    return this.privacy.me(user);
  }

  @Post('me/accept')
  @HttpCode(200)
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  accept(@CurrentUser() user: User, @Body() dto: AcceptPolicyDto) {
    return this.privacy.accept(user, dto.version);
  }

  /** RF-50: revocar el consentimiento. La cuenta queda inactiva. */
  @Post('me/revoke')
  @HttpCode(200)
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  revoke(@CurrentUser() user: User, @Body() dto: ConfirmWithPasswordDto) {
    return this.privacy.revoke(user, dto.password);
  }

  /** RF-50: pedir la supresión. Borra el contacto y anonimiza los pedidos. */
  @Post('me/delete')
  @HttpCode(200)
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  suppress(@CurrentUser() user: User, @Body() dto: ConfirmWithPasswordDto) {
    return this.privacy.suppress(user, dto.password);
  }

  /** RF-51, CU-47: quién abrió cada fórmula. El administrador no ve la fórmula. */
  @Get('prescription-access')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  accessLog(@Query() query: AccessLogQueryDto) {
    return this.privacy.accessLog(query);
  }
}
