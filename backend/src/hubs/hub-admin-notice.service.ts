import { Injectable, Logger } from '@nestjs/common';
import { Hub } from './hub.entity';

@Injectable()
export class HubAdminNoticeService {
  private readonly logger = new Logger(HubAdminNoticeService.name);

  notifyPendingApproval(hub: Hub): void {
    this.logger.log(`Central pendiente de aprobación: ${hub.id} (${hub.name})`);
  }

  notifyDecision(hub: Hub): void {
    this.logger.log(
      `Central ${hub.status}: ${hub.id} (${hub.name})`,
    );
  }
}
