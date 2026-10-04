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
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
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
import { CreateHubPlanDto } from './dto/create-hub-plan.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { RejectOrderDto } from './dto/reject-order.dto';
import { DeliveryPlan } from './delivery-plan.entity';
import { CatalogRow, InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  NOT_THE_SUPPLYING_HUB,
  NO_STOCK_MESSAGE,
  ONCE_IS_NOT_EXTENDED,
  ORIGIN_STOCK_MESSAGE,
  PLAN_ALREADY_CANCELLED,
  PLAN_CANCELLED_REASON,
  PLAN_NOT_READY_TO_EXTEND,
  SAME_HUB_MESSAGE,
  SPECIAL_CONTROL_MESSAGE,
  assertCoordinates,
  assertNoPatientFormula,
  assertStartDate,
  assertStillReceived,
  datesForExtension,
  isUnattendedEmergency,
  occurrenceDates,
  patientFormula,
  renewalDue,
  todayInColombia,
  windowEnd,
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
    @InjectRepository(DeliveryPlan)
    private readonly plans: Repository<DeliveryPlan>,
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
        planId: null,
        scheduledFor: null,
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
        planId: null,
        scheduledFor: null,
      }),
    );
    return this.toPublicOrder(saved);
  }

  async createPlan(user: User, dto: CreatePlanDto) {
    this.requireRequester(user);
    const image = patientFormula(user, dto.saleType, dto);
    const coords = assertCoordinates(dto.latitude, dto.longitude);
    const offer = await this.requireOffer(
      dto.medicationName,
      dto.saleType,
      undefined,
      dto.quantity,
    );
    return this.persistPlan(
      {
        frequency: dto.frequency,
        medicationName: offer.name,
        saleType: dto.saleType,
        requiresColdChain: offer.requiresColdChain,
        quantity: dto.quantity,
        startDate: dto.startDate,
        requesterId: user.id,
        createdByUserId: user.id,
        destinationKind: DestinationKind.PERSON,
        destinationHubId: null,
        originHubId: null,
        address: dto.address,
        latitude: coords.latitude,
        longitude: coords.longitude,
      },
      image,
      dto.prescriptionMime ?? null,
    );
  }

  async createHubPlan(user: User, dto: CreateHubPlanDto) {
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
    return this.persistPlan(
      {
        frequency: dto.frequency,
        medicationName: offer.name,
        saleType: dto.saleType,
        requiresColdChain: offer.requiresColdChain,
        quantity: dto.quantity,
        startDate: dto.startDate,
        requesterId: null,
        createdByUserId: user.id,
        destinationKind: DestinationKind.HUB,
        destinationHubId: destination.id,
        originHubId: origin.id,
        address: destination.address,
        latitude: destination.latitude,
        longitude: destination.longitude,
      },
      null,
      null,
    );
  }

  async listPlans(user: User) {
    const plans = await this.plans.find({
      where: this.ownedPlanWhere(user),
      order: { createdAt: 'DESC' },
    });
    return plans.map((plan) => this.toPublicPlan(plan));
  }

  async findPlan(user: User, id: string) {
    const plan = await this.requireOwnedPlan(user, id);
    const occurrences = await this.orders.find({
      where: { planId: plan.id },
      order: { scheduledFor: 'ASC' },
    });
    return {
      ...this.toPublicPlan(plan),
      occurrences: occurrences.map((order) => ({
        id: order.id,
        status: order.status,
        scheduledFor: order.scheduledFor,
        droneId: order.droneId,
      })),
    };
  }

  async extendPlan(user: User, id: string) {
    const plan = await this.requireOwnedPlan(user, id);
    this.assertCanExtend(plan);
    const today = todayInColombia();
    const extension = datesForExtension(
      plan.startDate,
      plan.windowEndsOn,
      plan.frequency,
      today,
    );
    plan.windowEndsOn = extension.windowEndsOn;
    await this.plans.save(plan);
    const image = await this.formulaForPlan(plan);
    for (const scheduledFor of extension.dates) {
      await this.saveOccurrence(plan, scheduledFor, image);
    }
    return this.toPublicPlan(plan);
  }

  async cancelPlan(user: User, id: string) {
    const plan = await this.requireOwnedPlan(user, id);
    if (plan.status === PlanStatus.CANCELLED) {
      throw new BadRequestException(PLAN_ALREADY_CANCELLED);
    }
    plan.status = PlanStatus.CANCELLED;
    await this.plans.save(plan);
    await this.orders.update(
      { planId: plan.id, status: OrderStatus.RECEIVED },
      {
        status: OrderStatus.CANCELLED,
        statusReason: PLAN_CANCELLED_REASON,
      },
    );
    return this.toPublicPlan(plan);
  }

  async listScheduled(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const stock = await this.stockByKey(hub.id);
    const pending = await this.orders.find({
      where: {
        missionType: MissionType.SCHEDULED,
        status: OrderStatus.RECEIVED,
      },
      order: { scheduledFor: 'ASC' },
    });
    return pending
      .filter((order) => this.isDirectedToHub(order, hub.id, stock))
      .map((order) => ({
        ...this.toPublicOrder(order),
        availableQuantity: this.availableAt(order, stock),
      }));
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
        unattended: isUnattendedEmergency(order.createdAt),
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

  async listMine(user: User) {
    if (user.role !== UserRole.REQUESTER) {
      throw new ForbiddenException('Solo el solicitante ve su historial.');
    }
    const orders = await this.orders.find({
      where: { requesterId: user.id },
      order: { createdAt: 'DESC', status: 'ASC' },
    });
    return orders.map((order) => this.toPublicOrder(order));
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

  private async persistPlan(
    input: {
      frequency: PlanFrequency;
      medicationName: string;
      saleType: SaleType;
      requiresColdChain: boolean;
      quantity: number;
      startDate: string;
      requesterId: string | null;
      createdByUserId: string;
      destinationKind: DestinationKind;
      destinationHubId: string | null;
      originHubId: string | null;
      address: string;
      latitude: number | null;
      longitude: number | null;
    },
    image: Buffer | null,
    mime: string | null,
  ) {
    assertStartDate(input.startDate);
    const dates = occurrenceDates(
      input.startDate,
      windowEnd(input.startDate),
      input.frequency,
    );
    const plan = await this.plans.save(
      this.plans.create({
        ...input,
        status: PlanStatus.ACTIVE,
        windowEndsOn: windowEnd(input.startDate),
      }),
    );
    for (const scheduledFor of dates) {
      await this.saveOccurrence(
        plan,
        scheduledFor,
        image ? { content: image, mime: mime ?? 'image/jpeg' } : null,
      );
    }
    return this.toPublicPlan(plan);
  }

  private async saveOccurrence(
    plan: DeliveryPlan,
    scheduledFor: string,
    image: { content: Buffer; mime: string } | null,
  ) {
    const saved = await this.orders.save(
      this.orders.create({
        missionType: MissionType.SCHEDULED,
        destinationKind: plan.destinationKind,
        status: OrderStatus.RECEIVED,
        priority: OrderPriority.NORMAL,
        medicationName: plan.medicationName,
        saleType: plan.saleType,
        requiresColdChain: plan.requiresColdChain,
        quantity: plan.quantity,
        description: null,
        requesterId: plan.requesterId,
        createdByUserId: plan.createdByUserId,
        destinationHubId: plan.destinationHubId,
        originHubId: plan.originHubId,
        address: plan.address,
        latitude: plan.latitude,
        longitude: plan.longitude,
        droneId: null,
        statusReason: null,
        planId: plan.id,
        scheduledFor,
      }),
    );
    if (image) {
      await this.images.save(
        this.images.create({
          orderId: saved.id,
          content: image.content,
          mime: image.mime,
        }),
      );
    }
    return saved;
  }

  private async formulaForPlan(plan: DeliveryPlan) {
    if (plan.saleType !== SaleType.PRESCRIPTION) {
      return null;
    }
    const existing = await this.orders.findOne({ where: { planId: plan.id } });
    if (!existing) {
      return null;
    }
    const image = await this.images.findOne({
      where: { orderId: existing.id },
    });
    if (!image) {
      return null;
    }
    return { content: image.content, mime: image.mime };
  }

  private assertCanExtend(plan: DeliveryPlan) {
    if (plan.status === PlanStatus.CANCELLED) {
      throw new BadRequestException(PLAN_ALREADY_CANCELLED);
    }
    if (plan.frequency === PlanFrequency.ONCE) {
      throw new BadRequestException(ONCE_IS_NOT_EXTENDED);
    }
    if (!renewalDue(plan, todayInColombia())) {
      throw new BadRequestException(PLAN_NOT_READY_TO_EXTEND);
    }
  }

  private ownedPlanWhere(
    user: User,
  ): { requesterId: string } | { createdByUserId: string } {
    if (user.role === UserRole.REQUESTER) {
      return { requesterId: user.id };
    }
    if (user.role === UserRole.DISPATCHER) {
      return { createdByUserId: user.id };
    }
    throw new ForbiddenException('No puedes consultar estos planes.');
  }

  private async requireOwnedPlan(user: User, id: string) {
    const plan = await this.plans.findOne({
      where: { id, ...this.ownedPlanWhere(user) },
    });
    if (!plan) {
      throw new NotFoundException('El plan no existe.');
    }
    return plan;
  }

  private toPublicPlan(plan: DeliveryPlan) {
    return {
      id: plan.id,
      frequency: plan.frequency,
      status: plan.status,
      medicationName: plan.medicationName,
      saleType: plan.saleType,
      requiresColdChain: plan.requiresColdChain,
      quantity: plan.quantity,
      startDate: plan.startDate,
      windowEndsOn: plan.windowEndsOn,
      destinationKind: plan.destinationKind,
      originHubId: plan.originHubId,
      destinationHubId: plan.destinationHubId,
      address: plan.address,
      latitude: plan.latitude,
      longitude: plan.longitude,
      hasPrescription: plan.saleType === SaleType.PRESCRIPTION,
      renewalDue: renewalDue(plan, todayInColombia()),
      createdAt: plan.createdAt,
    };
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
      planId: order.planId,
      scheduledFor: order.scheduledFor,
      hasPrescription: order.saleType === SaleType.PRESCRIPTION,
      createdAt: order.createdAt,
    };
  }
}
