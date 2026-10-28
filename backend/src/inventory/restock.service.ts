import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { ReturnOutcome } from '../common/enums/return-outcome.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { HubsService } from '../hubs/hubs.service';
import { Order } from '../orders/order.entity';
import { presentOrder } from '../orders/order.presenter';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { InventoryItem } from './inventory-item.entity';
import { QuarantineRecord } from './quarantine-record.entity';
import {
  NOT_THE_RETURN_HUB,
  ONLY_RETURNED_IS_CHECKED,
  RETURN_ALREADY_CHECKED,
  quarantineReasonFor,
} from './restock.rules';

export const DISPATCHED_LOT_MISSING =
  'No se encontró el lote que salió con este pedido.';

type DispatchedLot = { lot: string; expirationDate: string };

/**
 * El insumo que vuelve al estante: el paquete devuelto que pasa la revisión
 * reingresa en origen, el que no queda en cuarentena, y un traslado recibido
 * entra en la central de destino.
 */
@Injectable()
export class RestockService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly hubsService: HubsService,
  ) {}

  /** CU de retorno, pasos 4 y 5: el despachador de origen revisa el empaque. */
  async checkReturn(user: User, orderId: string, packagingIntact: boolean) {
    const hubId = await this.requireDispatcherHubId(user);
    const order = await this.dataSource.transaction(async (manager) => {
      const current = await manager.findOne(Order, {
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!current) {
        throw new NotFoundException('El pedido no existe.');
      }
      if (current.originHubId !== hubId) {
        throw new ForbiddenException(NOT_THE_RETURN_HUB);
      }
      if (current.status !== OrderStatus.RETURNED) {
        throw new BadRequestException(ONLY_RETURNED_IS_CHECKED);
      }
      if (current.returnCheckedAt) {
        throw new BadRequestException(RETURN_ALREADY_CHECKED);
      }
      const lot = await this.dispatchedLot(manager, current);
      const reason = quarantineReasonFor({
        coldChainAlert: current.coldChainAlertAt != null,
        packagingIntact,
        receiptSealIntact: current.receiptSealIntact,
      });
      if (reason) {
        await manager.save(
          manager.create(QuarantineRecord, {
            orderId: current.id,
            hubId,
            medicationName: current.medicationName,
            saleType: current.saleType,
            lot: lot.lot,
            expirationDate: lot.expirationDate,
            quantity: current.quantity,
            reason,
          }),
        );
      } else {
        await this.addUnits(
          manager,
          hubId,
          current,
          lot,
          current.inventoryItemId,
        );
      }
      current.returnCheckedAt = new Date();
      current.returnOutcome = reason
        ? ReturnOutcome.QUARANTINED
        : ReturnOutcome.RESTOCKED;
      return manager.save(current);
    });
    return presentOrder(order);
  }

  /** centrales.md, paso 5: el traslado recibido entra en la central de destino. */
  async receiveTransfer(manager: EntityManager, order: Order): Promise<void> {
    if (!order.destinationHubId) {
      return;
    }
    const lot = await this.dispatchedLot(manager, order);
    await this.addUnits(manager, order.destinationHubId, order, lot, null);
  }

  /**
   * Los pedidos cargados antes de guardar el registro de salida lo toman
   * del ítem reservado, si todavía existe.
   */
  private async dispatchedLot(
    manager: EntityManager,
    order: Order,
  ): Promise<DispatchedLot> {
    if (order.dispatchedLot && order.dispatchedLotExpiresOn) {
      return {
        lot: order.dispatchedLot,
        expirationDate: order.dispatchedLotExpiresOn,
      };
    }
    const item = order.inventoryItemId
      ? await manager.findOne(InventoryItem, {
          where: { id: order.inventoryItemId },
        })
      : null;
    if (!item) {
      throw new ConflictException(DISPATCHED_LOT_MISSING);
    }
    return { lot: item.lot, expirationDate: item.expirationDate };
  }

  /**
   * Suma al mismo lote (el ítem del que salió, o uno igual en esa central);
   * si ya no existe, lo crea con los datos del registro de salida.
   */
  private async addUnits(
    manager: EntityManager,
    hubId: string,
    order: Order,
    lot: DispatchedLot,
    sourceItemId: string | null,
  ): Promise<void> {
    const source = sourceItemId
      ? await manager.findOne(InventoryItem, {
          where: { id: sourceItemId, hubId },
          lock: { mode: 'pessimistic_write' },
        })
      : null;
    const same =
      source ??
      (await manager
        .createQueryBuilder(InventoryItem, 'item')
        .where('item.hubId = :hubId', { hubId })
        .andWhere('LOWER(item.name) = :name', {
          name: order.medicationName.trim().toLowerCase(),
        })
        .andWhere('item.lot = :lot', { lot: lot.lot })
        .andWhere('item.expirationDate = :expirationDate', {
          expirationDate: lot.expirationDate,
        })
        .andWhere('item.saleType = :saleType', { saleType: order.saleType })
        .setLock('pessimistic_write')
        .getOne());
    if (same) {
      same.quantity += order.quantity;
      await manager.save(same);
      return;
    }
    await manager.save(
      manager.create(InventoryItem, {
        hubId,
        name: order.medicationName,
        quantity: order.quantity,
        lot: lot.lot,
        expirationDate: lot.expirationDate,
        requiresColdChain: order.requiresColdChain,
        saleType: order.saleType,
      }),
    );
  }

  /** Lo que la central del despachador tiene en cuarentena, lo más nuevo primero. */
  async listQuarantine(user: User) {
    const hubId = await this.requireDispatcherHubId(user);
    return this.dataSource.getRepository(QuarantineRecord).find({
      where: { hubId },
      order: { createdAt: 'DESC' },
    });
  }

  private async requireDispatcherHubId(user: User): Promise<string> {
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException(
        'Solo el despachador gestiona el inventario de su central.',
      );
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new ForbiddenException(
        'Debes tener una central asignada para gestionar pedidos.',
      );
    }
    const hub = await this.hubsService.requireActive(hubIds[0]);
    return hub.id;
  }
}
