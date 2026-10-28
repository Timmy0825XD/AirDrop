import {
  Controller,
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
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../users/user.entity';
import { InboxService } from './inbox.service';

/** La bandeja de avisos de cada cuenta, cualquier rol. */
@ApiTags('Avisos')
@ApiBearerAuth()
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class InboxController {
  constructor(private readonly inbox: InboxService) {}

  @Get()
  list(@CurrentUser() user: User, @Query('unread') unread?: string) {
    return this.inbox.list(user, unread === 'true');
  }

  @Patch(':id/read')
  markRead(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.inbox.markRead(user, id);
  }

  @Post('read-all')
  @HttpCode(200)
  markAllRead(@CurrentUser() user: User) {
    return this.inbox.markAllRead(user);
  }
}
