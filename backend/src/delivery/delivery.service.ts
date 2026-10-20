import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { generateOtp, hashOtp } from '../auth/auth.rules';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { presentOrder } from '../orders/order.presenter';
import { Mission } from '../simulation/mission.entity';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { DeliveryCode } from './delivery-code.entity';
import {
  DELIVERY_CODE_REJECTED,
  DELIVERY_WAIT_EXPIRED,
  ONLY_AWAITING_DELIVERY_IS_DELIVERED,
  ORDER_ALREADY_DELIVERED,
  deliveryCodeMatches,
  deliveryExpiresAt,
  isDeliveryCodeUsable,
} from './delivery.rules';

@Injectable()
export class DeliveryService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationsService,
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
        manager.create(DeliveryCode, { orderId, usedAt: null });
      stored.codeHash = hashOtp(code);
      stored.expiresAt = expiresAt;
      await manager.save(stored);
      return { code, expiresAt };
    });
  }

  /** Cierra la entrega: marca el código usado, entrega el pedido y libera el dron. */
  async validate(user: User, orderId: string, code: string) {
    const delivered = await this.dataSource.transaction(async (manager) => {
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
      if (
        !stored ||
        !isDeliveryCodeUsable(stored, now) ||
        !deliveryCodeMatches(code, stored.codeHash)
      ) {
        throw new BadRequestException(DELIVERY_CODE_REJECTED);
      }
      stored.usedAt = now;
      await manager.save(stored);
      order.status = OrderStatus.DELIVERED;
      const saved = await manager.save(order);
      if (order.droneId) {
        await manager.update(
          Drone,
          { id: order.droneId },
          { status: DroneStatus.AVAILABLE },
        );
      }
      return saved;
    });
    await this.notifications.statusChanged(orderId, OrderStatus.DELIVERED);
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
