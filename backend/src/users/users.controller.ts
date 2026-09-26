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
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from './user.entity';
import { CreateInstitutionalUserDto } from './dto/create-institutional-user.dto';
import { ListInstitutionalUsersQueryDto } from './dto/list-institutional-users-query.dto';
import { SetUserSuspensionDto } from './dto/set-user-suspension.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  async create(
    @CurrentUser() actor: User,
    @Body() dto: CreateInstitutionalUserDto,
  ) {
    const saved = await this.usersService.createInstitutional(actor, dto);
    return this.usersService.toPublicUser(saved);
  }

  @Get()
  async list(@Query() query: ListInstitutionalUsersQueryDto) {
    const rows = await this.usersService.listInstitutional(query);
    return rows.map((row) => this.usersService.toPublicUser(row));
  }

  @Patch(':id/suspension')
  async setSuspension(
    @CurrentUser() actor: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: SetUserSuspensionDto,
  ) {
    const saved = await this.usersService.setSuspension(
      actor,
      id,
      dto.suspended,
    );
    return this.usersService.toPublicUser(saved);
  }
}
