import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { generateOtp, hashOtp } from '../auth/auth.rules';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { presentOrder } from '../orders/order.presenter';
import { FlightClockService } from '../simulation/flight-clock.service';
import { Mission } from '../simulation/mission.entity';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { DeliveryCode } from './delivery-code.entity';
import {
  DELIVERY_CODE_LOCKED,
  DELIVERY_CODE_REJECTED,
  DELIVERY_WAIT_EXPIRED,
  ONLY_AWAITING_DELIVERY_IS_DELIVERED,
  ORDER_ALREADY_DELIVERED,
  deliveryCodeMatches,
  deliveryExpiresAt,
  isDeliveryCodeLocked,
  isDeliveryCodeUsable,
} from './delivery.rules';

@Injectable()
export class DeliveryService {
  private readonly logger = new Logger(DeliveryService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationsService,
    private readonly flights: FlightClockService,
  ) {}

  /** CU-19: el solicitante pide el código cuando el dron ya aterrizó. */
  async generate(user: User, orderId: string) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockRecipientOrder(manager, user, orderId);
      if (order.status === OrderStatus.DELIVERED) {
        throw new BadRequestException(ORDER_ALREADY_DELIVERED);
      }
      if (order.status !== OrderStatus.AWAITING_DELIVERY) {
        throw new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED);
      }
      const mission = await manager.findOne(Mission, { where: { orderId } });
      if (!mission?.landedAt) {
        throw new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED);
      }
      const expiresAt = deliveryExpiresAt(mission.landedAt);
      if (expiresAt.getTime() <= Date.now()) {
        throw new BadRequestException(DELIVERY_WAIT_EXPIRED);
      }
      const code = generateOtp();
      const stored =
        (await manager.findOne(DeliveryCode, { where: { orderId } })) ??
        manager.create(DeliveryCode, { orderId, usedAt: null, attempts: 0 });
      stored.codeHash = hashOtp(code);
      stored.expiresAt = expiresAt;
      await manager.save(stored);
      return { code, expiresAt };
    });
  }

  /**
   * Cierra la entrega: marca el código usado y entrega el pedido. El dron no
   * queda libre en destino: vuelve a su central y se libera al aterrizar.
   */
  async validate(user: User, orderId: string, code: string) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockRecipientOrder(manager, user, orderId);
      if (order.status === OrderStatus.DELIVERED) {
        throw new BadRequestException(DELIVERY_CODE_REJECTED);
      }
      if (order.status !== OrderStatus.AWAITING_DELIVERY) {
        throw new BadRequestException(ONLY_AWAITING_DELIVERY_IS_DELIVERED);
      }
      const stored = await manager.findOne(DeliveryCode, {
        where: { orderId },
      });
      const now = new Date();
      if (!stored || !isDeliveryCodeUsable(stored, now)) {
        throw new BadRequestException(DELIVERY_CODE_REJECTED);
      }
      if (isDeliveryCodeLocked(stored)) {
        throw new BadRequestException(DELIVERY_CODE_LOCKED);
      }
      if (!deliveryCodeMatches(code, stored.codeHash)) {
        // El intento queda guardado: por eso no se lanza dentro de la transacción.
        stored.attempts += 1;
        await manager.save(stored);
        return {
          rejection: isDeliveryCodeLocked(stored)
            ? DELIVERY_CODE_LOCKED
            : DELIVERY_CODE_REJECTED,
        };
      }
      stored.usedAt = now;
      await manager.save(stored);
      order.status = OrderStatus.DELIVERED;
      return { delivered: await manager.save(order) };
    });
    if ('rejection' in result) {
      throw new BadRequestException(result.rejection);
    }
    const { delivered } = result;
    await this.notifications.statusChanged(orderId, OrderStatus.DELIVERED);
    try {
      await this.flights.startReturn(orderId);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'regreso';
      this.logger.error(
        `No se pudo iniciar el regreso del dron ${orderId}: ${message}. Se reintenta al reiniciar.`,
      );
    }
    return presentOrder(delivered);
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
