import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderPriority } from '../common/enums/order-priority.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { CIVIL_EMERGENCY_QUANTITY } from '../common/field-limits';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { CreateHubEmergencyDto } from './dto/create-hub-emergency.dto';
import { RejectOrderDto } from './dto/reject-order.dto';
import { CatalogRow, InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  NOT_THE_SUPPLYING_HUB,
  NO_STOCK_MESSAGE,
  ORIGIN_STOCK_MESSAGE,
  SAME_HUB_MESSAGE,
  SPECIAL_CONTROL_MESSAGE,
  assertCoordinates,
  assertNoPatientFormula,
  assertStillReceived,
  patientFormula,
} from './orders.rules';
import { PrescriptionImage } from './prescription-image.entity';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(PrescriptionImage)
    private readonly images: Repository<PrescriptionImage>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    private readonly offers: InventoryOfferQuery,
    private readonly hubsService: HubsService,
  ) {}

  async catalog(user: User, query: CatalogQueryDto) {
    if (query.hubId) {
      this.requireDispatcher(user);
      return this.offers.catalog(query.hubId);
    }
    if (user.role !== UserRole.REQUESTER && user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException('No puedes consultar el catálogo.');
    }
    const rows = await this.offers.catalog();
    return rows.map(({ name, saleType, requiresColdChain }) => ({
      name,
      saleType,
      requiresColdChain,
    }));
  }

  async listOriginHubs(user: User) {
    const mine = await this.requireDispatcherHub(user);
    const rows = await this.hubs.find({
      where: { status: HubStatus.ACTIVE },
      order: { name: 'ASC' },
    });
    return rows
      .filter((hub) => hub.id !== mine.id)
      .map((hub) => ({ id: hub.id, name: hub.name, address: hub.address }));
  }

  async createEmergency(user: User, dto: CreateEmergencyDto) {
    this.requireRequester(user);
    const image = patientFormula(user, dto.saleType, dto);
    const coords = assertCoordinates(dto.latitude, dto.longitude);
    const offer = await this.requireOffer(dto.medicationName, dto.saleType);
    const saved = await this.orders.save(
      this.orders.create({
        missionType: MissionType.EMERGENCY,
        destinationKind: DestinationKind.PERSON,
        status: OrderStatus.RECEIVED,
        priority: OrderPriority.HIGH,
        medicationName: offer.name,
        saleType: dto.saleType,
        requiresColdChain: offer.requiresColdChain,
        quantity: CIVIL_EMERGENCY_QUANTITY,
        description: dto.description,
        requesterId: user.id,
        createdByUserId: user.id,
        destinationHubId: null,
        originHubId: null,
        address: dto.address,
        latitude: coords.latitude,
        longitude: coords.longitude,
        droneId: null,
        statusReason: null,
      }),
    );
    if (image) {
      await this.images.save(
        this.images.create({
          orderId: saved.id,
          content: image,
          mime: dto.prescriptionMime ?? 'image/jpeg',
        }),
      );
    }
    return this.toPublicOrder(saved);
  }

  async createHubEmergency(user: User, dto: CreateHubEmergencyDto) {
    const destination = await this.requireDispatcherHub(user);
    assertNoPatientFormula(dto);
    const origin = await this.hubsService.requireActive(dto.originHubId);
    if (origin.id === destination.id) {
      throw new BadRequestException(SAME_HUB_MESSAGE);
    }
    const offer = await this.requireOffer(
      dto.medicationName,
      dto.saleType,
      origin.id,
      dto.quantity,
    );
    const saved = await this.orders.save(
      this.orders.create({
        missionType: MissionType.EMERGENCY,
        destinationKind: DestinationKind.HUB,
        status: OrderStatus.RECEIVED,
        priority: OrderPriority.HIGH,
        medicationName: offer.name,
        saleType: dto.saleType,
        requiresColdChain: offer.requiresColdChain,
        quantity: dto.quantity,
        description: null,
        requesterId: null,
        createdByUserId: user.id,
        destinationHubId: destination.id,
        originHubId: origin.id,
        address: destination.address,
        latitude: destination.latitude,
        longitude: destination.longitude,
        droneId: null,
        statusReason: null,
      }),
    );
    return this.toPublicOrder(saved);
  }

  async listQueue(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const stock = await this.stockByKey(hub.id);
    const pending = await this.orders.find({
      where: {
        missionType: MissionType.EMERGENCY,
        status: OrderStatus.RECEIVED,
      },
      order: { createdAt: 'ASC' },
    });
    return pending
      .filter((order) => this.isDirectedToHub(order, hub.id, stock))
      .map((order) => ({
        ...this.toPublicOrder(order),
        availableQuantity: this.availableAt(order, stock),
      }));
  }

  async readPrescription(user: User, id: string) {
    const hub = await this.requireDispatcherHub(user);
    const order = await this.orders.findOne({ where: { id } });
    const stock = order ? await this.stockByKey(hub.id) : null;
    if (
      !order ||
      !stock ||
      order.missionType !== MissionType.EMERGENCY ||
      order.status !== OrderStatus.RECEIVED ||
      order.destinationKind !== DestinationKind.PERSON ||
      order.saleType !== SaleType.PRESCRIPTION ||
      !this.isDirectedToHub(order, hub.id, stock)
    ) {
      throw new NotFoundException('El pedido no existe.');
    }
    const image = await this.images.findOne({ where: { orderId: order.id } });
    if (!image) {
      throw new NotFoundException('El pedido no existe.');
    }
    return { content: image.content, mime: image.mime };
  }

  async findOne(user: User, id: string) {
    const order = await this.requireReadable(user, id);
    return this.toPublicOrder(order);
  }

  async reject(user: User, id: string, dto: RejectOrderDto) {
    const hub = await this.requireDispatcherHub(user);
    const order = await this.orders.findOne({ where: { id } });
    if (!order) {
      throw new NotFoundException('El pedido no existe.');
    }
    assertStillReceived(order.status);
    await this.assertSupplyingHub(hub.id, order);
    order.status = OrderStatus.REJECTED;
    order.statusReason = dto.reason;
    return this.toPublicOrder(await this.orders.save(order));
  }

  private async requireOffer(
    name: string,
    saleType: SaleType,
    hubId?: string,
    minQuantity = 1,
  ) {
    if (saleType === SaleType.SPECIAL_CONTROL) {
      throw new BadRequestException(SPECIAL_CONTROL_MESSAGE);
    }
    const offer = await this.offers.offer(name, saleType, hubId);
    if (!offer || offer.availableQuantity < minQuantity) {
      throw new BadRequestException(
        hubId ? ORIGIN_STOCK_MESSAGE : NO_STOCK_MESSAGE,
      );
    }
    return offer;
  }

  private requireRequester(user: User) {
    if (user.role !== UserRole.REQUESTER) {
      throw new ForbiddenException('Solo el solicitante crea este pedido.');
    }
  }

  private requireDispatcher(user: User) {
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException(
        'Solo el despachador consulta el stock de una central.',
      );
    }
  }

  private async requireDispatcherHub(user: User) {
    this.requireDispatcher(user);
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new ForbiddenException(
        'Debes tener una central asignada para gestionar pedidos.',
      );
    }
    return this.hubsService.requireActive(hubIds[0]);
  }

  private async requireReadable(user: User, id: string) {
    const order = await this.orders.findOne({ where: { id } });
    if (!order || !this.canRead(user, order)) {
      throw new NotFoundException('El pedido no existe.');
    }
    return order;
  }

  private canRead(user: User, order: Order): boolean {
    if (user.role === UserRole.REQUESTER) {
      return order.requesterId === user.id;
    }
    if (user.role !== UserRole.DISPATCHER) {
      return false;
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      return false;
    }
    const hubId = hubIds[0];
    return (
      order.createdByUserId === user.id ||
      order.originHubId === hubId ||
      order.destinationHubId === hubId
    );
  }

  private async stockByKey(hubId: string) {
    const rows = await this.offers.stockForHub(hubId);
    return new Map(
      rows.map((row) => [this.offerKey(row.name, row.saleType), row]),
    );
  }

  private offerKey(name: string, saleType: SaleType) {
    return `${name.trim().toLowerCase()}|${saleType}`;
  }

  private availableAt(order: Order, stock: Map<string, CatalogRow>) {
    return (
      stock.get(this.offerKey(order.medicationName, order.saleType))
        ?.availableQuantity ?? 0
    );
  }

  private isDirectedToHub(
    order: Order,
    hubId: string,
    stock: Map<string, CatalogRow>,
  ) {
    if (order.originHubId) {
      return order.originHubId === hubId;
    }
    return this.availableAt(order, stock) >= order.quantity;
  }

  private async assertSupplyingHub(hubId: string, order: Order) {
    if (order.originHubId) {
      if (order.originHubId !== hubId) {
        throw new ForbiddenException(NOT_THE_SUPPLYING_HUB);
      }
      return;
    }
    const offer = await this.offers.offer(
      order.medicationName,
      order.saleType,
      hubId,
    );
    if (!offer || offer.availableQuantity < order.quantity) {
      throw new ForbiddenException(NOT_THE_SUPPLYING_HUB);
    }
  }

  private toPublicOrder(order: Order) {
    return {
      id: order.id,
      missionType: order.missionType,
      destinationKind: order.destinationKind,
      status: order.status,
      priority: order.priority,
      medicationName: order.medicationName,
      saleType: order.saleType,
      requiresColdChain: order.requiresColdChain,
      quantity: order.quantity,
      description: order.description,
      requesterId: order.requesterId,
      createdByUserId: order.createdByUserId,
      destinationHubId: order.destinationHubId,
      originHubId: order.originHubId,
      address: order.address,
      latitude: order.latitude,
      longitude: order.longitude,
      droneId: order.droneId,
      statusReason: order.statusReason,
      hasPrescription: order.saleType === SaleType.PRESCRIPTION,
      createdAt: order.createdAt,
    };
  }
}
