import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectDataSource } from '@nestjs/typeorm';
import { randomBytes } from 'node:crypto';
import {
  Between,
  DataSource,
  EntityManager,
  FindOptionsWhere,
  In,
  LessThanOrEqual,
  MoreThanOrEqual,
} from 'typeorm';
import { hashPassword, passwordsMatch } from '../auth/auth.rules';
import { OneTimeCode } from '../auth/one-time-code.entity';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import { PrescriptionAccessPurpose } from '../common/enums/prescription-access-purpose.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Notification } from '../notifications/notification.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { DeliveryPlan } from '../orders/delivery-plan.entity';
import { Order } from '../orders/order.entity';
import { NOT_YET_AUTHORIZED } from '../orders/plan-occurrence.rules';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import {
  DEFAULT_CONTACT_EMAIL,
  DEFAULT_CONTROLLER_NAME,
  POLICY_VERSION,
  privacyPolicy,
} from './privacy-policy';
import {
  IN_PROGRESS_STATUSES,
  ONLY_REQUESTERS,
  ORDER_IN_PROGRESS,
  POLICY_NOT_ACCEPTED,
  POLICY_VERSION_MISMATCH,
  REVOKED_REASON,
  REVOKE_NOTICE,
  SUPPRESSED_REASON,
  SUPPRESS_NOTICE,
  WRONG_PASSWORD,
  mustAcceptPolicy,
  pseudonym,
} from './privacy.rules';
import { PrescriptionAccess } from './prescription-access.entity';

/** Estados en que la central todavía está decidiendo: abrirla es para autorizar. */
const AUTHORIZING_STATUSES = [
  OrderStatus.RECEIVED,
  OrderStatus.REASSIGNED,
  OrderStatus.UNDER_REVIEW,
];

/**
 * RF-50 y RF-51 (`context/legal/datos.md`): la política versionada, los
 * derechos del titular (consultar, corregir, revocar, suprimir) y el
 * registro de quién abre cada fórmula. El consentimiento va en hora real,
 * como la autenticación.
 */
@Injectable()
export class PrivacyService {
  private readonly logger = new Logger(PrivacyService.name);

  constructor(
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly config: ConfigService,
    private readonly users: UsersService,
    private readonly notifications: NotificationsService,
  ) {}

  policy() {
    return privacyPolicy({
      name:
        this.config.get<string>('PRIVACY_CONTROLLER_NAME') ||
        DEFAULT_CONTROLLER_NAME,
      contactEmail:
        this.config.get<string>('PRIVACY_CONTACT_EMAIL') ||
        DEFAULT_CONTACT_EMAIL,
    });
  }

  /** CU-46: sus datos, la versión que aceptó y lo que pasa si revoca o suprime. */
  me(user: User) {
    return {
      user: this.users.toPublicUser(user),
      consent: consentView(user),
      notices: { revoke: REVOKE_NOTICE, suppress: SUPPRESS_NOTICE },
    };
  }

  /** RF-50: acepta la versión vigente (al registrarse o en el siguiente ingreso). */
  async accept(user: User, version: string) {
    if (version !== POLICY_VERSION) {
      throw new BadRequestException(POLICY_VERSION_MISMATCH);
    }
    user.consentAcceptedAt = new Date();
    user.consentPolicyVersion = POLICY_VERSION;
    await this.dataSource.getRepository(User).save(user);
    return consentView(user);
  }

  /** RF-50: sin la política vigente aceptada, el solicitante no pide. */
  assertPolicyAccepted(user: User): void {
    if (
      user.role === UserRole.REQUESTER &&
      !user.simulated &&
      mustAcceptPolicy(user.consentPolicyVersion ?? null)
    ) {
      throw new ForbiddenException(POLICY_NOT_ACCEPTED);
    }
  }

  /**
   * RF-50: revocar deja la cuenta inactiva. Lo que todavía no tiene dron se
   * cancela; lo que ya salió termina. Los datos siguen ahí.
   */
  async revoke(user: User, password: string) {
    await this.assertOwner(user, password);
    const cancelled = await this.dataSource.transaction(async (manager) => {
      const ids = await this.cancelPending(manager, user.id, REVOKED_REASON);
      await manager.update(
        User,
        { id: user.id },
        { status: UserStatus.REVOKED, consentRevokedAt: new Date() },
      );
      return ids;
    });
    await this.announceCancelled(cancelled);
    return { status: UserStatus.REVOKED, cancelledOrders: cancelled.length };
  }

  /**
   * RF-50: la supresión borra el contacto y el acceso y anonimiza los
   * pedidos. El medicamento, el lote, la fecha y el punto se conservan
   * (deber de conservación de la dispensación). Con un pedido en curso,
   * espera.
   */
  async suppress(user: User, password: string) {
    await this.assertOwner(user, password);
    const inProgress = await this.dataSource.getRepository(Order).count({
      where: { requesterId: user.id, status: In(IN_PROGRESS_STATUSES) },
    });
    if (inProgress > 0) {
      throw new ConflictException(ORDER_IN_PROGRESS);
    }
    const alias = pseudonym();
    const result = await this.dataSource.transaction(async (manager) => {
      const cancelled = await this.cancelPending(
        manager,
        user.id,
        SUPPRESSED_REASON,
      );
      const orders = await this.anonymizeOrders(manager, user.id, alias);
      await manager.delete(OneTimeCode, { userId: user.id });
      await manager.delete(Notification, { userId: user.id });
      await manager.update(
        User,
        { id: user.id },
        {
          fullName: alias,
          email: null,
          pendingEmail: null,
          phone: null,
          documentType: null,
          documentNumber: null,
          allergies: null,
          // Nadie conoce esta contraseña: la cuenta ya no tiene acceso.
          passwordHash: await hashPassword(randomBytes(24).toString('hex')),
          status: UserStatus.DELETED,
          suppressedAt: new Date(),
        },
      );
      return { cancelled, orders };
    });
    await this.announceCancelled(result.cancelled);
    this.logger.log(`Datos suprimidos: ${result.orders} pedidos anonimizados`);
    return {
      status: UserStatus.DELETED,
      anonymizedOrders: result.orders,
      cancelledOrders: result.cancelled.length,
    };
  }

  /**
   * RF-51: quién abrió la fórmula, con qué rol, cuándo, desde qué pedido y
   * para qué. Sin propósito explícito: autorizar si la central todavía
   * decide, histórico si no.
   */
  async recordAccess(
    user: User,
    orderId: string,
    fileIndex: number | null,
    purpose?: PrescriptionAccessPurpose,
  ): Promise<void> {
    let why = purpose;
    if (!why) {
      const order = await this.dataSource.getRepository(Order).findOne({
        where: { id: orderId },
        select: { id: true, status: true },
      });
      why =
        order && AUTHORIZING_STATUSES.includes(order.status)
          ? PrescriptionAccessPurpose.AUTHORIZE
          : PrescriptionAccessPurpose.HISTORY;
    }
    const repo = this.dataSource.getRepository(PrescriptionAccess);
    await repo.save(
      repo.create({
        orderId,
        userId: user.id,
        role: user.role,
        purpose: why,
        fileIndex,
        accessedAt: new Date(),
      }),
    );
  }

  /** CU-47: el administrador ve el registro, nunca la fórmula. */
  async accessLog(query: {
    orderId?: string;
    userId?: string;
    from?: string;
    to?: string;
  }) {
    const where: FindOptionsWhere<PrescriptionAccess> = {};
    if (query.orderId) {
      where.orderId = query.orderId;
    }
    if (query.userId) {
      where.userId = query.userId;
    }
    const from = query.from ? new Date(`${query.from}T00:00:00-05:00`) : null;
    const to = query.to ? new Date(`${query.to}T23:59:59.999-05:00`) : null;
    if (from && to) {
      where.accessedAt = Between(from, to);
    } else if (from) {
      where.accessedAt = MoreThanOrEqual(from);
    } else if (to) {
      where.accessedAt = LessThanOrEqual(to);
    }
    const rows = await this.dataSource.getRepository(PrescriptionAccess).find({
      where,
      order: { accessedAt: 'DESC' },
      take: 200,
    });
    const people = rows.length
      ? await this.dataSource.getRepository(User).find({
          where: { id: In([...new Set(rows.map((row) => row.userId))]) },
          select: { id: true, fullName: true },
        })
      : [];
    return rows.map((row) => ({
      id: row.id,
      orderId: row.orderId,
      userId: row.userId,
      userName:
        people.find((person) => person.id === row.userId)?.fullName ?? null,
      role: row.role,
      purpose: row.purpose,
      fileIndex: row.fileIndex,
      accessedAt: row.accessedAt.toISOString(),
    }));
  }

  private async assertOwner(user: User, password: string): Promise<void> {
    if (user.role !== UserRole.REQUESTER) {
      throw new ForbiddenException(ONLY_REQUESTERS);
    }
    if (!(await passwordsMatch(password, user.passwordHash))) {
      throw new BadRequestException(WRONG_PASSWORD);
    }
  }

  /** Lo que todavía no tiene dron, y los planes activos, quedan cancelados. */
  private async cancelPending(
    manager: EntityManager,
    userId: string,
    reason: string,
  ): Promise<string[]> {
    const pending = await manager.find(Order, {
      where: { requesterId: userId, status: In(NOT_YET_AUTHORIZED) },
      select: { id: true },
    });
    const ids = pending.map((order) => order.id);
    if (ids.length) {
      await manager.update(
        Order,
        { id: In(ids) },
        { status: OrderStatus.CANCELLED, statusReason: reason },
      );
    }
    await manager.update(
      DeliveryPlan,
      { requesterId: userId, status: PlanStatus.ACTIVE },
      { status: PlanStatus.CANCELLED },
    );
    return ids;
  }

  /**
   * El nombre y el documento del paciente a cargo pasan a ser el
   * identificador; la nota libre y las alergias se borran porque pueden
   * identificar. El titular ya no se identifica: su fila queda anonimizada.
   */
  private async anonymizeOrders(
    manager: EntityManager,
    userId: string,
    alias: string,
  ): Promise<number> {
    const result = await manager.query<[unknown, number]>(
      `UPDATE orders SET
         "patientFullName" = CASE WHEN "patientFullName" IS NULL THEN NULL ELSE $2 END,
         "patientDocumentNumber" = CASE WHEN "patientDocumentNumber" IS NULL THEN NULL ELSE $2 END,
         description = NULL,
         allergies = NULL
       WHERE "requesterId" = $1`,
      [userId, alias],
    );
    await manager.query(
      `UPDATE delivery_plans SET
         "patientFullName" = CASE WHEN "patientFullName" IS NULL THEN NULL ELSE $2 END,
         "patientDocumentNumber" = CASE WHEN "patientDocumentNumber" IS NULL THEN NULL ELSE $2 END
       WHERE "requesterId" = $1`,
      [userId, alias],
    );
    return Array.isArray(result) ? Number(result[1] ?? 0) : 0;
  }

  /** CU-29: el aviso por el socket nunca tumba lo que ya se guardó. */
  private async announceCancelled(ids: string[]): Promise<void> {
    for (const id of ids) {
      try {
        await this.notifications.statusChanged(id, OrderStatus.CANCELLED);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'socket';
        this.logger.warn(`No se pudo avisar del pedido ${id}: ${message}`);
      }
    }
  }
}

function consentView(user: User) {
  const accepted = user.consentPolicyVersion ?? null;
  return {
    acceptedAt: user.consentAcceptedAt
      ? new Date(user.consentAcceptedAt).toISOString()
      : null,
    acceptedVersion: accepted,
    currentVersion: POLICY_VERSION,
    mustAccept: mustAcceptPolicy(accepted),
  };
}
