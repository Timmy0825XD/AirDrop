import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { hashPassword } from '../auth/auth.rules';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PrescriptionAccessPurpose } from '../common/enums/prescription-access-purpose.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import {
  DEFAULT_CONTROLLER_NAME,
  POLICY_VERSION,
} from './privacy-policy';
import {
  ONLY_REQUESTERS,
  ORDER_IN_PROGRESS,
  POLICY_NOT_ACCEPTED,
  POLICY_VERSION_MISMATCH,
  REVOKED_REASON,
  WRONG_PASSWORD,
  compareVersions,
  mustAcceptPolicy,
  pseudonym,
} from './privacy.rules';
import { PrivacyService } from './privacy.service';

const PASSWORD = 'Password123';

async function holder(overrides: Partial<User> = {}): Promise<User> {
  return {
    id: 'user-1',
    fullName: 'Valentina Rodríguez',
    email: 'valentina@gmail.com',
    phone: '3015550101',
    role: UserRole.REQUESTER,
    status: UserStatus.ACTIVE,
    simulated: false,
    consentPolicyVersion: POLICY_VERSION,
    consentAcceptedAt: new Date('2026-11-14T12:00:00.000Z'),
    passwordHash: await hashPassword(PASSWORD),
    hubAssignments: [],
    ...overrides,
  } as User;
}

function build(options: { inProgress?: number; pending?: string[] } = {}) {
  const manager = {
    find: jest
      .fn()
      .mockResolvedValue((options.pending ?? []).map((id) => ({ id }))),
    update: jest.fn().mockResolvedValue({ affected: 1 }),
    delete: jest.fn().mockResolvedValue({ affected: 1 }),
    query: jest.fn().mockResolvedValue([[], 3]),
  };
  const repos = new Map<string, Record<string, jest.Mock>>();
  const repo = (name: string) => {
    if (!repos.has(name)) {
      repos.set(name, {
        count: jest.fn().mockResolvedValue(options.inProgress ?? 0),
        save: jest.fn((row: object) => Promise.resolve(row)),
        create: jest.fn((row: object) => row),
        findOne: jest
          .fn()
          .mockResolvedValue({ id: 'order-1', status: OrderStatus.RECEIVED }),
        find: jest.fn().mockResolvedValue([]),
      });
    }
    return repos.get(name)!;
  };
  const dataSource = {
    transaction: jest.fn((work: (m: typeof manager) => unknown) =>
      work(manager),
    ),
    getRepository: jest.fn((entity: { name: string }) => repo(entity.name)),
  };
  const notifications = {
    statusChanged: jest.fn().mockResolvedValue(undefined),
  };
  const service = new PrivacyService(
    dataSource as never,
    { get: () => undefined } as never,
    { toPublicUser: (user: User) => ({ id: user.id }) } as never,
    notifications as never,
  );
  return { service, manager, repo, notifications };
}

describe('Política versionada (RF-50)', () => {
  it('la política trae responsable, versión y las secciones del art. 13', () => {
    const policy = build().service.policy();
    expect(policy.version).toBe(POLICY_VERSION);
    expect(policy.controller.name).toBe(DEFAULT_CONTROLLER_NAME);
    expect(policy.sections.map((section) => section.title)).toContain(
      'Tus derechos (Ley 1581, art. 8)',
    );
  });

  it('pide aceptar si no hay versión o si es anterior a la sustancial', () => {
    expect(mustAcceptPolicy(null)).toBe(true);
    expect(mustAcceptPolicy('0.9')).toBe(true);
    expect(mustAcceptPolicy(POLICY_VERSION)).toBe(false);
    expect(compareVersions('1.10', '1.9')).toBeGreaterThan(0);
  });

  it('sin la versión vigente aceptada, el solicitante no crea pedidos', async () => {
    const { service } = build();
    expect(() =>
      service.assertPolicyAccepted({
        role: UserRole.REQUESTER,
        consentPolicyVersion: null,
      } as User),
    ).toThrow(new ForbiddenException(POLICY_NOT_ACCEPTED));
    const current = await holder();
    expect(() => service.assertPolicyAccepted(current)).not.toThrow();
  });

  it('acepta solo la versión vigente', async () => {
    const { service } = build();
    const user = await holder({ consentPolicyVersion: null });
    await expect(service.accept(user, '0.1')).rejects.toThrow(
      new BadRequestException(POLICY_VERSION_MISMATCH),
    );
    await expect(service.accept(user, POLICY_VERSION)).resolves.toMatchObject({
      acceptedVersion: POLICY_VERSION,
      mustAccept: false,
    });
  });
});

describe('Revocar y suprimir (RF-50, CU-46)', () => {
  it('revocar pide la contraseña, cancela lo que no tiene dron y deja la cuenta inactiva', async () => {
    const { service, manager, notifications } = build({ pending: ['o1', 'o2'] });
    const user = await holder();
    await expect(service.revoke(user, 'otra')).rejects.toThrow(
      new BadRequestException(WRONG_PASSWORD),
    );
    const result = await service.revoke(user, PASSWORD);
    expect(result).toEqual({ status: UserStatus.REVOKED, cancelledOrders: 2 });
    expect(manager.update).toHaveBeenCalledWith(
      Order,
      expect.anything(),
      { status: OrderStatus.CANCELLED, statusReason: REVOKED_REASON },
    );
    expect(manager.update).toHaveBeenCalledWith(
      User,
      { id: 'user-1' },
      expect.objectContaining({ status: UserStatus.REVOKED }),
    );
    expect(notifications.statusChanged).toHaveBeenCalledTimes(2);
  });

  it('el personal no revoca desde aquí', async () => {
    const { service } = build();
    await expect(
      service.revoke(await holder({ role: UserRole.DISPATCHER }), PASSWORD),
    ).rejects.toThrow(new ForbiddenException(ONLY_REQUESTERS));
  });

  it('con un pedido en curso, la supresión espera', async () => {
    const { service, manager } = build({ inProgress: 1 });
    await expect(service.suppress(await holder(), PASSWORD)).rejects.toThrow(
      new ConflictException(ORDER_IN_PROGRESS),
    );
    expect(manager.update).not.toHaveBeenCalled();
  });

  it('suprimir borra contacto y acceso, y anonimiza los pedidos con un identificador', async () => {
    const { service, manager } = build();
    const result = await service.suppress(await holder(), PASSWORD);
    expect(result.status).toBe(UserStatus.DELETED);
    const userUpdate = manager.update.mock.calls.find(
      ([entity]) => entity === User,
    )!;
    const changes = userUpdate[2] as Record<string, unknown>;
    expect(changes).toMatchObject({
      email: null,
      phone: null,
      documentNumber: null,
      allergies: null,
      status: UserStatus.DELETED,
    });
    expect(changes.fullName).toMatch(/^ANON-[0-9a-f]{8}$/);
    const [ordersSql, params] = manager.query.mock.calls[0] as [
      string,
      string[],
    ];
    expect(ordersSql).toContain('"patientFullName"');
    expect(ordersSql).not.toContain('medicationName');
    expect(params[1]).toBe(changes.fullName);
  });

  it('el identificador no se deriva de la persona', () => {
    expect(pseudonym(() => Buffer.from([0xde, 0xad, 0xbe, 0xef]))).toBe(
      'ANON-deadbeef',
    );
  });
});

describe('Registro de acceso a fórmulas (RF-51)', () => {
  it('guarda quién, con qué rol, desde qué pedido y para qué', async () => {
    const { service, repo } = build();
    const dispatcher = await holder({ role: UserRole.DISPATCHER });
    await service.recordAccess(dispatcher, 'order-1', 0);
    expect(repo('PrescriptionAccess').save).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'order-1',
        userId: 'user-1',
        role: UserRole.DISPATCHER,
        purpose: PrescriptionAccessPurpose.AUTHORIZE,
        fileIndex: 0,
      }),
    );
  });

  it('un pedido que ya salió se consulta desde el histórico, salvo que digan otra cosa', async () => {
    const { service, repo } = build();
    repo('Order').findOne.mockResolvedValue({
      id: 'order-1',
      status: OrderStatus.DELIVERED,
    });
    const dispatcher = await holder({ role: UserRole.DISPATCHER });
    await service.recordAccess(dispatcher, 'order-1', 1);
    await service.recordAccess(
      dispatcher,
      'order-1',
      1,
      PrescriptionAccessPurpose.CLAIM,
    );
    const purposes = repo('PrescriptionAccess').save.mock.calls.map(
      ([row]) => (row as { purpose: string }).purpose,
    );
    expect(purposes).toEqual([
      PrescriptionAccessPurpose.HISTORY,
      PrescriptionAccessPurpose.CLAIM,
    ]);
  });
});
