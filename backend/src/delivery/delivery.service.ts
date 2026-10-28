import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { RestockService } from '../inventory/restock.service';
import {
  RECEIPT_CHECK_REQUIRED,
  receiptRejection,
} from '../inventory/restock.rules';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { presentOrder } from '../orders/order.presenter';
import { FlightClockService } from '../simulation/flight-clock.service';
import { Mission } from '../simulation/mission.entity';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { DeliveryCode } from './delivery-code.entity';
import { ValidateDeliveryCodeDto } from './dto/validate-delivery-code.dto';
import {
  DELIVERY_CODE_LOCKED,
  DELIVERY_CODE_NOT_AVAILABLE,
  DELIVERY_CODE_NOT_READY,
  DELIVERY_CODE_REJECTED,
  DELIVERY_WAIT_EXPIRED,
  ONLY_AWAITING_DELIVERY_IS_DELIVERED,
  ORDER_ALREADY_DELIVERED,
  deliveryCodeFor,
  deliveryCodeMatches,
  deliveryExpiresAt,
  isDeliveryCodeLocked,
  isDeliveryCodeUsable,
} from './delivery.rules';

/** Pedidos para los que ya hay un código que mostrar. */
const CODE_VISIBLE = [
  OrderStatus.PENDING_LOAD,
  OrderStatus.IN_FLIGHT,
  OrderStatus.AWAITING_DELIVERY,
];

/** Pedidos que todavía no pasan por la confirmación de carga. */
const BEFORE_LOAD = [
  OrderStatus.RECEIVED,
  OrderStatus.UNDER_REVIEW,
  OrderStatus.ASSIGNED,
];

@Injectable()
export class DeliveryService {
  private readonly logger = new Logger(DeliveryService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationsService,
    private readonly flights: FlightClockService,
    private readonly config: ConfigService,
    private readonly restock: RestockService,
  ) {}

  /**
   * Lo que ve quien recibe: el código desde que se confirma la carga y, una vez
   * que el dron aterriza, hasta cuándo puede ingresarlo (`expiresAt`).
   */
  async show(user: User, orderId: string) {
    const manager = this.dataSource.manager;
    const order = await manager.findOne(Order, { where: { id: orderId } });
    if (!order || !isRecipient(user, order)) {
      throw new NotFoundException('El pedido no existe.');
    }
    if (order.status === OrderStatus.DELIVERED) {
      throw new BadRequestException(ORDER_ALREADY_DELIVERED);
    }
    if (
      BEFORE_LOAD.includes(order.status) ||
      (order.status === OrderStatus.PENDING_LOAD && !order.loadConfirmedAt)
    ) {
      throw new BadRequestException(DELIVERY_CODE_NOT_READY);
    }
    if (!CODE_VISIBLE.includes(order.status) || !order.loadConfirmedAt) {
      throw new BadRequestException(DELIVERY_CODE_NOT_AVAILABLE);
    }
    let expiresAt: Date | null = null;
    if (order.status === OrderStatus.AWAITING_DELIVERY) {
      const mission = await manager.findOne(Mission, { where: { orderId } });
      if (mission?.landedAt) {
        expiresAt = deliveryExpiresAt(mission.landedAt);
        if (expiresAt.getTime() <= Date.now()) {
          throw new BadRequestException(DELIVERY_WAIT_EXPIRED);
        }
      }
    }
    return {
      code: deliveryCodeFor(
        { id: order.id, loadConfirmedAt: order.loadConfirmedAt },
        this.secret(),
      ),
      expiresAt,
    };
  }

  /**
   * Cierra la entrega: marca el código usado y entrega el pedido. El dron no
   * queda libre en destino: vuelve a su central y se libera al aterrizar.
   * En un traslado, quien recibe compara la remisión y el sello: si algo
   * falla, o hubo alerta de frío, el paquete vuelve a origen (centrales.md).
   */
  async validate(user: User, orderId: string, dto: ValidateDeliveryCodeDto) {
    const code = dto.code;
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockRecipientOrder(manager, user, orderId);
      const toHub = order.destinationKind === DestinationKind.HUB;
      if (
        toHub &&
        (dto.remissionMatches === undefined || dto.sealIntact === undefined)
      ) {
        throw new BadRequestException(RECEIPT_CHECK_REQUIRED);
      }
      if (order.status === OrderStatus.DELIVERED) {
        throw new BadRequestException(DELIVERY_CODE_REJECTED);
      }
      if (
        order.status === OrderStatus.RETURNING &&
        (await this.isLocked(manager, orderId))
      ) {
        // Ya se agotaron los intentos y el dron va de regreso con el paquete.
        throw new BadRequestException(DELIVERY_CODE_LOCKED);
      }
      if (order.status !== OrderStatus.AWAITING_DELIVERY) {
        throw new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED);
      }
      const mission = await manager.findOne(Mission, { where: { orderId } });
      if (!mission?.landedAt || !order.loadConfirmedAt) {
        throw new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED);
      }
      const state =
        (await manager.findOne(DeliveryCode, { where: { orderId } })) ??
        manager.create(DeliveryCode, { orderId, usedAt: null, attempts: 0 });
      const now = new Date();
      if (!isDeliveryCodeUsable(state, mission.landedAt, now)) {
        throw new BadRequestException(DELIVERY_CODE_REJECTED);
      }
      if (isDeliveryCodeLocked(state)) {
        throw new BadRequestException(DELIVERY_CODE_LOCKED);
      }
      const expected = deliveryCodeFor(
        { id: order.id, loadConfirmedAt: order.loadConfirmedAt },
        this.secret(),
      );
      if (!deliveryCodeMatches(code, expected)) {
        // El intento queda guardado: por eso no se lanza dentro de la transacción.
        state.attempts += 1;
        await manager.save(state);
        const locked = isDeliveryCodeLocked(state);
        return {
          rejection: locked ? DELIVERY_CODE_LOCKED : DELIVERY_CODE_REJECTED,
          locked,
        };
      }
      state.usedAt = now;
      await manager.save(state);
      if (toHub) {
        const rejected = receiptRejection({
          coldChainAlert: order.coldChainAlertAt != null,
          remissionMatches: dto.remissionMatches === true,
          sealIntact: dto.sealIntact === true,
        });
        if (rejected) {
          order.status = OrderStatus.RETURNING;
          order.receiptRejectedReason = rejected;
          order.receiptSealIntact = dto.sealIntact === true;
          return { refused: await manager.save(order) };
        }
        await this.restock.receiveTransfer(manager, order);
      }
      order.status = OrderStatus.DELIVERED;
      return { delivered: await manager.save(order), deliveredAt: now };
    });
    if ('rejection' in result) {
      if (result.locked) {
        await this.returnWithPackageSafely(orderId);
      }
      throw new BadRequestException(result.rejection);
    }
    if ('refused' in result && result.refused) {
      await this.notifications.statusChanged(orderId, OrderStatus.RETURNING);
      await this.startReturnSafely(orderId);
      return presentOrder(result.refused);
    }
    const { delivered, deliveredAt } = result;
    await this.notifications.statusChanged(orderId, OrderStatus.DELIVERED);
    // El dron espera el minuto de retiro antes de volver (fase `unloading`).
    await this.flights.schedulePickup(orderId, deliveredAt);
    return presentOrder(delivered);
  }

  /**
   * Quinto código equivocado: el dron no sigue esperando, vuelve ya con el
   * paquete. El bloqueo queda guardado aunque el regreso no arranque.
   */
  private async returnWithPackageSafely(orderId: string): Promise<void> {
    try {
      await this.flights.returnWithPackage(orderId);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'regreso';
      this.logger.error(
        `No se pudo iniciar el regreso con el paquete ${orderId}: ${message}. Sale al vencer la espera.`,
      );
    }
  }

  private async isLocked(
    manager: EntityManager,
    orderId: string,
  ): Promise<boolean> {
    const state = await manager.findOne(DeliveryCode, { where: { orderId } });
    return state != null && isDeliveryCodeLocked(state);
  }

  /** La entrega o el rechazo ya quedaron guardados aunque el regreso no arranque. */
  private async startReturnSafely(orderId: string): Promise<void> {
    try {
      await this.flights.startReturn(orderId);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'regreso';
      this.logger.error(
        `No se pudo iniciar el regreso del dron ${orderId}: ${message}. Se reintenta al reiniciar.`,
      );
    }
  }

  private secret(): string {
    return this.config.getOrThrow<string>('JWT_SECRET');
  }

  /**
   * Quien recibe ingresa el código: el solicitante si el destino es una
   * persona, o el despachador de la central de destino si es una central.
   */
  private async lockRecipientOrder(
    manager: EntityManager,
    user: User,
    orderId: string,
  ): Promise<Order> {
    const order = await manager.findOne(Order, {
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order || !isRecipient(user, order)) {
      throw new NotFoundException('El pedido no existe.');
    }
    return order;
  }
}

function isRecipient(user: User, order: Order): boolean {
  if (order.destinationKind === DestinationKind.HUB) {
    return (
      user.role === UserRole.DISPATCHER &&
      order.destinationHubId !== null &&
      assignedHubIds(user).includes(order.destinationHubId)
    );
  }
  return user.role === UserRole.REQUESTER && order.requesterId === user.id;
}
