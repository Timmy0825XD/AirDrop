import { Module } from '@nestjs/common';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { NotificationsService } from './notifications.service';

@Module({
  imports: [TelemetryModule],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
