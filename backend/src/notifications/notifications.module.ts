import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BrevoMailService } from '../mail/brevo-mail.service';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { User } from '../users/user.entity';
import { InboxController } from './inbox.controller';
import { InboxService } from './inbox.service';
import { Notification } from './notification.entity';
import { NotificationsService } from './notifications.service';

@Module({
  imports: [
    TelemetryModule,
    TypeOrmModule.forFeature([Notification, User, UserHubAssignment]),
  ],
  controllers: [InboxController],
  providers: [NotificationsService, InboxService, BrevoMailService],
  exports: [NotificationsService, InboxService],
})
export class NotificationsModule {}
