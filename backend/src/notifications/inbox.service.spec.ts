import { NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IsNull, Repository } from 'typeorm';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { BrevoMailService } from '../mail/brevo-mail.service';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { User } from '../users/user.entity';
import { InboxService } from './inbox.service';
import { Notification } from './notification.entity';

const ana = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  fullName: 'Ana Pérez',
  email: 'ana@gmail.com',
} as User;

const notice = {
  kind: NotificationKind.CONFIRM_DELIVERY,
  orderId: '11111111-1111-4111-8111-111111111111',
  title: 'Confirma tu entrega programada',
  body: 'Llega el jueves.',
};

function build(state: { env?: string; mailConfigured?: boolean } = {}) {
  const notifications = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: object) => Promise.resolve(value)),
    find: jest.fn().mockResolvedValue([]),
    findOne: jest.fn().mockResolvedValue(null),
    update: jest.fn().mockResolvedValue({ affected: 3 }),
  };
  const users = { findOne: jest.fn().mockResolvedValue(ana) };
  const assignments = {
    find: jest.fn().mockResolvedValue([{ user: ana }]),
  };
  const mail = {
    isConfigured: jest.fn().mockReturnValue(state.mailConfigured ?? true),
    send: jest.fn().mockResolvedValue(undefined),
  };
  const config = {
    get: jest.fn().mockReturnValue(state.env ?? 'development'),
  };
  const service = new InboxService(
    notifications as unknown as Repository<Notification>,
    users as unknown as Repository<User>,
    assignments as unknown as Repository<UserHubAssignment>,
    mail as unknown as BrevoMailService,
    config as unknown as ConfigService,
  );
  return { service, notifications, assignments, mail };
}

describe('InboxService', () => {
  it('guarda el aviso en la bandeja y lo manda al correo', async () => {
    const { service, notifications, mail } = build();
    await service.notifyUser(ana.id, notice);
    expect(notifications.save).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: ana.id,
        kind: NotificationKind.CONFIRM_DELIVERY,
        readAt: null,
      }),
    );
    expect(mail.send).toHaveBeenCalledWith(
      expect.objectContaining({
        toEmail: 'ana@gmail.com',
        subject: notice.title,
      }),
    );
  });

  it('si el correo falla, el aviso igual queda', async () => {
    const { service, notifications, mail } = build();
    mail.send.mockRejectedValueOnce(new Error('Brevo caído'));
    await expect(service.notifyUser(ana.id, notice)).resolves.toBeUndefined();
    expect(notifications.save).toHaveBeenCalled();
  });

  it('en pruebas, o sin Brevo, no manda correo', async () => {
    for (const state of [{ env: 'test' }, { mailConfigured: false }]) {
      const { service, mail } = build(state);
      await service.notifyUser(ana.id, notice);
      expect(mail.send).not.toHaveBeenCalled();
    }
  });

  it('a una central le llega a sus despachadores activos', async () => {
    const { service, assignments, notifications } = build();
    await service.notifyHubDispatchers('hub', notice);
    expect(assignments.find).toHaveBeenCalledWith({
      where: {
        hubId: 'hub',
        user: { role: UserRole.DISPATCHER, status: UserStatus.ACTIVE },
      },
      relations: { user: true },
    });
    expect(notifications.save).toHaveBeenCalledTimes(1);
  });

  it('lista solo lo de la cuenta y marca como leído', async () => {
    const { service, notifications } = build();
    await service.list(ana, true);
    expect(notifications.find).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: ana.id, readAt: IsNull() } }),
    );
    await expect(service.markRead(ana, 'otro')).rejects.toThrow(
      NotFoundException,
    );
    await expect(service.markAllRead(ana)).resolves.toEqual({ updated: 3 });
  });
});
