import {
  BadRequestException,
  ForbiddenException,
  Injectable,
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
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  NO_STOCK_MESSAGE,
  ORIGIN_STOCK_MESSAGE,
  SAME_HUB_MESSAGE,
  SPECIAL_CONTROL_MESSAGE,
  assertCoordinates,
  assertNoPatientFormula,
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
      }),
    );
    return this.toPublicOrder(saved);
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
      hasPrescription: order.saleType === SaleType.PRESCRIPTION,
      createdAt: order.createdAt,
    };
  }
}
