import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { UsersModule } from '../users/users.module';
import { Hub } from './hub.entity';
import { HubAdminNoticeService } from './hub-admin-notice.service';
import { HubsController } from './hubs.controller';
import { HubsService } from './hubs.service';

@Module({
  imports: [TypeOrmModule.forFeature([Hub]), UsersModule, AuthModule],
  controllers: [HubsController],
  providers: [HubsService, HubAdminNoticeService],
  exports: [HubsService],
})
export class HubsModule {}
