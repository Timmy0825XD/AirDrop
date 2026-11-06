import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { HubOutageService } from './hub-outage.service';
import { Hub } from './hub.entity';
import { HubsController } from './hubs.controller';
import { HubsService } from './hubs.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Hub]),
    AuthModule,
    TelemetryModule,
    NotificationsModule,
  ],
  controllers: [HubsController],
  providers: [HubsService, HubOutageService],
  exports: [HubsService, HubOutageService],
})
export class HubsModule {}
