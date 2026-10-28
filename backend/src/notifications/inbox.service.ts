import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { BrevoMailService } from '../mail/brevo-mail.service';
import { renderNoticeEmail } from '../mail/notice-email';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { User } from '../users/user.entity';
import { Notification } from './notification.entity';

export type Notice = {
  kind: NotificationKind;
  orderId?: string | null;
  title: string;
  body: string;
};

const PAGE_SIZE = 50;

/**
 * Bandeja de avisos (RU-05): guarda el aviso en la cuenta y lo manda al
 * correo. El correo es un extra: si falla, el aviso igual queda.
 */
@Injectable()
export class InboxService {
  private readonly logger = new Logger(InboxService.name);

  constructor(
    @InjectRepository(Notification)
    private readonly notifications: Repository<Notification>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(UserHubAssignment)
    private readonly assignments: Repository<UserHubAssignment>,
    private readonly mail: BrevoMailService,
    private readonly config: ConfigService,
  ) {}

  async notifyUser(userId: string, notice: Notice): Promise<void> {
    const user = await this.users.findOne({ where: { id: userId } });
    if (!user) {
      return;
    }
    await this.deliver(user, notice);
  }

  /** A los despachadores activos de una central. */
  async notifyHubDispatchers(hubId: string, notice: Notice): Promise<void> {
    const rows = await this.assignments.find({
      where: {
        hubId,
        user: { role: UserRole.DISPATCHER, status: UserStatus.ACTIVE },
      },
      relations: { user: true },
    });
    for (const row of rows) {
      await this.deliver(row.user, notice);
    }
  }

  list(user: User, unreadOnly: boolean) {
    return this.notifications.find({
      where: unreadOnly
        ? { userId: user.id, readAt: IsNull() }
        : { userId: user.id },
      order: { createdAt: 'DESC' },
      take: PAGE_SIZE,
    });
  }

  async markRead(user: User, id: string) {
    const notification = await this.notifications.findOne({
      where: { id, userId: user.id },
    });
    if (!notification) {
      throw new NotFoundException('El aviso no existe.');
    }
    notification.readAt ??= new Date();
    return this.notifications.save(notification);
  }

  async markAllRead(user: User) {
    const result = await this.notifications.update(
      { userId: user.id, readAt: IsNull() },
      { readAt: new Date() },
    );
    return { updated: result.affected ?? 0 };
  }

  private async deliver(user: User, notice: Notice): Promise<void> {
    await this.notifications.save(
      this.notifications.create({
        userId: user.id,
        kind: notice.kind,
        orderId: notice.orderId ?? null,
        title: notice.title,
        body: notice.body,
        readAt: null,
      }),
    );
    if (!user.email || !this.mailEnabled()) {
      return;
    }
    try {
      await this.mail.send({
        toEmail: user.email,
        toName: user.fullName,
        subject: notice.title,
        html: renderNoticeEmail({
          name: user.fullName,
          title: notice.title,
          body: notice.body,
        }),
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'correo';
      this.logger.warn(`No se pudo enviar el aviso por correo: ${message}`);
    }
  }

  private mailEnabled(): boolean {
    const env = this.config.get<string>('NODE_ENV', 'development');
    return env !== 'test' && this.mail.isConfigured();
  }
}
