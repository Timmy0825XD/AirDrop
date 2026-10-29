import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { And, In, LessThan, MoreThanOrEqual, Repository } from 'typeorm';
import { resolvePeriod } from '../analytics/analytics.rules';
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
import { isAwaitingHub } from '../decision/fallback.rules';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { RoutePlannerService } from '../routing/route-planner.service';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { CreateHubEmergencyDto } from './dto/create-hub-emergency.dto';
import { CreateHubPlanDto } from './dto/create-hub-plan.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { HistoryQueryDto } from './dto/history-query.dto';
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
  addCalendarDays,
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
import { presentOrder } from './order.presenter';
import {
  NOT_YET_AUTHORIZED,
  initialOccurrenceState,
} from './plan-occurrence.rules';
import {
  Occurrence,
  PRESCRIPTION_VALIDITY_REQUIRED,
  PlanSchedule,
  SCHEDULE_LEAD_MS,
  SLOT_MS,
  buildSchedule,
  legacySchedule,
  slotFor,
} from './plan-schedule.rules';
import { PreviewPlanDto, UpdatePlanScheduleDto } from './dto/plan-schedule.dto';
import { PrescriptionImage } from './prescription-image.entity';
import { PrescriptionStorage } from './prescription-storage';

export const RULE_PLAN_NOT_EXTENDED =
  'Para alargar este plan cambia su calendario.';
export const PLAN_RESCHEDULED_REASON = 'Se cambió el calendario del plan.';
export const PLAN_ALREADY_PAUSED = 'El plan ya está en pausa.';
export const PLAN_NOT_PAUSED = 'El plan no está en pausa.';

/** Cuándo sale cada entrega de un plan y hasta cuándo cubre. */
type PlanTiming = {
  frequency: PlanFrequency | null;
  schedule: PlanSchedule;
  windowEndsOn: string;
  occurrences: Occurrence[];
  prescriptionValidUntil: string | null;
};

type PlanTimingInput = {
  frequency?: PlanFrequency;
  startDate?: string;
  schedule?: PreviewPlanDto['schedule'];
  prescriptionValidUntil?: string;
};

/** HU-36: estados con los que una misión ya no cambia. */
const CLOSED_STATUSES = [
  OrderStatus.DELIVERED,
  OrderStatus.RETURNED,
  OrderStatus.REJECTED,
  OrderStatus.REASSIGNED,
  OrderStatus.CANCELLED,
  OrderStatus.SKIPPED,
  OrderStatus.EXPIRED,
];

const DEFAULT_HISTORY_PAGE_SIZE = 20;

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(PrescriptionImage)
    private readonly images: Repository<PrescriptionImage>,
    private readonly storage: PrescriptionStorage,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    private readonly offers: InventoryOfferQuery,
    private readonly hubsService: HubsService,
    @InjectRepository(DeliveryPlan)
    private readonly plans: Repository<DeliveryPlan>,
    private readonly routes: RoutePlannerService,
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
    await this.assertDestinationAllowed(coords);
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
      await this.attachFormula(
        saved.id,
        image,
        dto.prescriptionMime ?? 'image/jpeg',
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
    await this.assertDestinationAllowed(coords);
    const offer = await this.requireOffer(
      dto.medicationName,
      dto.saleType,
      undefined,
      dto.quantity,
    );
    const timing = this.planTiming(dto, dto.saleType === SaleType.PRESCRIPTION);
    return this.persistPlan(
      {
        medicationName: offer.name,
        saleType: dto.saleType,
        requiresColdChain: offer.requiresColdChain,
        quantity: dto.quantity,
        requesterId: user.id,
        createdByUserId: user.id,
        destinationKind: DestinationKind.PERSON,
        destinationHubId: null,
        originHubId: null,
        address: dto.address,
        latitude: coords.latitude,
        longitude: coords.longitude,
      },
      timing,
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
    // Entre centrales no viaja la fórmula de un paciente: no hay vigencia.
    const timing = this.planTiming(dto, false);
    return this.persistPlan(
      {
        medicationName: offer.name,
        saleType: dto.saleType,
        requiresColdChain: offer.requiresColdChain,
        quantity: dto.quantity,
        requesterId: null,
        createdByUserId: user.id,
        destinationKind: DestinationKind.HUB,
        destinationHubId: destination.id,
        originHubId: origin.id,
        address: destination.address,
        latitude: destination.latitude,
        longitude: destination.longitude,
      },
      timing,
      null,
      null,
    );
  }

  /** RU-30: las fechas y franjas que dejaría un calendario, sin guardar nada. */
  previewPlan(user: User, dto: PreviewPlanDto) {
    if (user.role !== UserRole.REQUESTER && user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException('No puedes armar planes.');
    }
    const result = buildSchedule(dto.schedule, {
      prescriptionValidUntil: dto.prescriptionValidUntil ?? null,
    });
    return {
      schedule: result.schedule,
      lastDate: result.lastDate,
      windowMinutes: SLOT_MS / 60_000,
      occurrences: result.occurrences.map(presentOccurrence),
      tooSoon: result.tooSoon,
    };
  }

  /**
   * RU-30: cambia el calendario o la hora. Las entregas que todavía no
   * tienen dron, y empiezan en más de 2 horas, se rehacen con la regla
   * nueva; las demás no cambian y su fecha no se repite.
   */
  async updatePlanSchedule(user: User, id: string, dto: UpdatePlanScheduleDto) {
    const plan = await this.requireOwnedPlan(user, id);
    if (plan.status === PlanStatus.CANCELLED) {
      throw new BadRequestException(PLAN_ALREADY_CANCELLED);
    }
    const now = new Date();
    const result = buildSchedule(dto.schedule, {
      now,
      prescriptionValidUntil: plan.prescriptionValidUntil,
    });
    const current = await this.orders.find({ where: { planId: plan.id } });
    const replaceable = current.filter((order) => isReplaceable(order, now));
    const replaceableIds = new Set(replaceable.map((order) => order.id));
    const keptDates = new Set(
      current
        .filter(
          (order) =>
            !replaceableIds.has(order.id) &&
            order.status !== OrderStatus.CANCELLED &&
            order.scheduledFor,
        )
        .map((order) => order.scheduledFor as string),
    );
    const image = await this.formulaForPlan(plan);
    Object.assign(plan, scheduleColumns(result.schedule), {
      frequency: null,
      startDate: result.schedule.startDate,
      windowEndsOn: addCalendarDays(
        result.schedule.endDate ?? result.lastDate,
        1,
      ),
    });
    await this.plans.save(plan);
    if (replaceable.length) {
      await this.orders.update(
        { id: In([...replaceableIds]) },
        {
          status: OrderStatus.CANCELLED,
          statusReason: PLAN_RESCHEDULED_REASON,
        },
      );
    }
    for (const occurrence of result.occurrences) {
      if (!keptDates.has(occurrence.date)) {
        await this.saveOccurrence(plan, occurrence, image);
      }
    }
    return this.findPlan(user, plan.id);
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
        scheduledAt: order.scheduledAt ?? null,
        windowEndsAt: order.windowEndsAt ?? null,
        droneId: order.droneId,
      })),
    };
  }

  async extendPlan(user: User, id: string) {
    const plan = await this.requireOwnedPlan(user, id);
    const frequency = this.assertCanExtend(plan);
    const today = todayInColombia();
    const extension = datesForExtension(
      plan.startDate,
      plan.windowEndsOn,
      frequency,
      today,
    );
    plan.windowEndsOn = extension.windowEndsOn;
    await this.plans.save(plan);
    const image = await this.formulaForPlan(plan);
    for (const scheduledFor of extension.dates) {
      await this.saveOccurrence(
        plan,
        slotFor(scheduledFor, plan.deliveryTime),
        image,
      );
    }
    return this.toPublicPlan(plan);
  }

  /** RU-30: en pausa no hay avisos y las entregas se omiten a T-2 h. */
  async setPlanPaused(user: User, id: string, paused: boolean) {
    const plan = await this.requireOwnedPlan(user, id);
    if (plan.status === PlanStatus.CANCELLED) {
      throw new BadRequestException(PLAN_ALREADY_CANCELLED);
    }
    if (plan.paused === paused) {
      throw new BadRequestException(
        paused ? PLAN_ALREADY_PAUSED : PLAN_NOT_PAUSED,
      );
    }
    plan.paused = paused;
    return this.toPublicPlan(await this.plans.save(plan));
  }

  async cancelPlan(user: User, id: string) {
    const plan = await this.requireOwnedPlan(user, id);
    if (plan.status === PlanStatus.CANCELLED) {
      throw new BadRequestException(PLAN_ALREADY_CANCELLED);
    }
    plan.status = PlanStatus.CANCELLED;
    await this.plans.save(plan);
    await this.orders.update(
      { planId: plan.id, status: In(NOT_YET_AUTHORIZED) },
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
        status: In([OrderStatus.RECEIVED, OrderStatus.REASSIGNED]),
      },
      order: { scheduledFor: 'ASC' },
    });
    return pending
      .filter(
        (order) =>
          isAwaitingHub(order) && this.isDirectedToHub(order, hub.id, stock),
      )
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
        status: In([OrderStatus.RECEIVED, OrderStatus.REASSIGNED]),
      },
      order: { createdAt: 'ASC' },
    });
    // Lo reasignado desde otra central ya esperó una vez: va primero.
    return pending
      .filter(
        (order) =>
          isAwaitingHub(order) && this.isDirectedToHub(order, hub.id, stock),
      )
      .sort(
        (left, right) =>
          Number(right.status === OrderStatus.REASSIGNED) -
          Number(left.status === OrderStatus.REASSIGNED),
      )
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
      !isAwaitingHub(order) ||
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
    return {
      content: await this.storage.download(image.objectKey),
      mime: image.mime,
    };
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

  /** Traslados que otras centrales despachan hacia la central del despachador. */
  async listIncoming(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const orders = await this.orders.find({
      where: { destinationKind: DestinationKind.HUB, destinationHubId: hub.id },
      order: { createdAt: 'DESC' },
    });
    return orders.map((order) => this.toPublicOrder(order));
  }

  /**
   * HU-36: lo que la central despachó y ya cerró, del más nuevo al más
   * viejo. Con fechas, solo los pedidos creados en ese periodo.
   */
  async listHistory(user: User, query: HistoryQueryDto) {
    const hub = await this.requireDispatcherHub(user);
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_HISTORY_PAGE_SIZE;
    const period =
      query.from || query.to ? resolvePeriod(query.from, query.to) : null;
    const [rows, total] = await this.orders.findAndCount({
      where: {
        originHubId: hub.id,
        status: query.status ?? In(CLOSED_STATUSES),
        ...(period && {
          createdAt: And(MoreThanOrEqual(period.from), LessThan(period.to)),
        }),
      },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * pageSize,
      take: pageSize,
    });
    return {
      items: rows.map((order) => this.toPublicOrder(order)),
      total,
      page,
      pageSize,
    };
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
    assertStillReceived(order);
    await this.assertSupplyingHub(hub.id, order);
    order.status = OrderStatus.REJECTED;
    order.statusReason = dto.reason;
    return this.toPublicOrder(await this.orders.save(order));
  }

  private async assertDestinationAllowed(coords: {
    latitude: number | null;
    longitude: number | null;
  }) {
    if (coords.latitude == null || coords.longitude == null) {
      return;
    }
    await this.routes.assertDestinationAllowed({
      latitude: coords.latitude,
      longitude: coords.longitude,
    });
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
    if (!order || !(await this.canRead(user, order))) {
      throw new NotFoundException('El pedido no existe.');
    }
    return order;
  }

  private async canRead(user: User, order: Order): Promise<boolean> {
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
    if (
      order.createdByUserId === user.id ||
      order.originHubId === hubId ||
      order.destinationHubId === hubId
    ) {
      return true;
    }
    return this.isWaitingForHub(order, hubId);
  }

  /**
   * Pedido civil que todavía no tiene central de origen (se la pone la
   * autorización). La cola y los programados se lo muestran a toda central
   * con stock suficiente, así que esa central también puede abrirlo.
   */
  private async isWaitingForHub(order: Order, hubId: string) {
    if (order.originHubId || order.status !== OrderStatus.RECEIVED) {
      return false;
    }
    return this.isDirectedToHub(order, hubId, await this.stockByKey(hubId));
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

  /**
   * Con `schedule`, la regla nueva (RU-30). Sin ella, la frecuencia anterior:
   * 8 semanas y la franja es todo el horario operativo.
   */
  private planTiming(
    dto: PlanTimingInput,
    needsPrescriptionValidity: boolean,
  ): PlanTiming {
    if (dto.schedule) {
      if (needsPrescriptionValidity && !dto.prescriptionValidUntil) {
        throw new BadRequestException(PRESCRIPTION_VALIDITY_REQUIRED);
      }
      const result = buildSchedule(dto.schedule, {
        prescriptionValidUntil: dto.prescriptionValidUntil ?? null,
      });
      return {
        frequency: null,
        schedule: result.schedule,
        windowEndsOn: addCalendarDays(
          result.schedule.endDate ?? result.lastDate,
          1,
        ),
        occurrences: result.occurrences,
        prescriptionValidUntil: dto.prescriptionValidUntil ?? null,
      };
    }
    const frequency = dto.frequency as PlanFrequency;
    const startDate = dto.startDate as string;
    assertStartDate(startDate);
    const windowEndsOn = windowEnd(startDate);
    return {
      frequency,
      schedule: legacySchedule(frequency, startDate, windowEndsOn),
      windowEndsOn,
      occurrences: occurrenceDates(startDate, windowEndsOn, frequency).map(
        (date) => slotFor(date, null),
      ),
      prescriptionValidUntil: null,
    };
  }

  private async persistPlan(
    input: {
      medicationName: string;
      saleType: SaleType;
      requiresColdChain: boolean;
      quantity: number;
      requesterId: string | null;
      createdByUserId: string;
      destinationKind: DestinationKind;
      destinationHubId: string | null;
      originHubId: string | null;
      address: string;
      latitude: number | null;
      longitude: number | null;
    },
    timing: PlanTiming,
    image: Buffer | null,
    mime: string | null,
  ) {
    const plan = await this.plans.save(
      this.plans.create({
        ...input,
        ...scheduleColumns(timing.schedule),
        frequency: timing.frequency,
        startDate: timing.schedule.startDate,
        status: PlanStatus.ACTIVE,
        windowEndsOn: timing.windowEndsOn,
        prescriptionValidUntil: timing.prescriptionValidUntil,
      }),
    );
    for (const occurrence of timing.occurrences) {
      await this.saveOccurrence(
        plan,
        occurrence,
        image ? { content: image, mime: mime ?? 'image/jpeg' } : null,
      );
    }
    return this.toPublicPlan(plan);
  }

  private async saveOccurrence(
    plan: DeliveryPlan,
    occurrence: Occurrence,
    image: { content: Buffer; mime: string } | null,
  ) {
    const saved = await this.orders.save(
      this.orders.create({
        missionType: MissionType.SCHEDULED,
        destinationKind: plan.destinationKind,
        ...initialOccurrenceState(plan, occurrence, new Date()),
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
        scheduledFor: occurrence.date,
        scheduledAt: occurrence.scheduledAt,
        windowEndsAt: occurrence.windowEndsAt,
      }),
    );
    if (image) {
      await this.attachFormula(saved.id, image.content, image.mime);
    }
    return saved;
  }

  /**
   * El nombre del objeto lleva el id del pedido, así que el pedido se guarda
   * antes. Si la fórmula no queda guardada, el pedido se descarta para no dejar
   * una urgencia bajo fórmula sin imagen.
   */
  private async attachFormula(orderId: string, content: Buffer, mime: string) {
    try {
      const objectKey = await this.storage.upload(orderId, content, mime);
      await this.images.save(
        this.images.create({
          orderId,
          objectKey,
          mime,
        }),
      );
    } catch (error) {
      await this.orders.delete({ id: orderId });
      throw error;
    }
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
    return {
      content: await this.storage.download(image.objectKey),
      mime: image.mime,
    };
  }

  /** Solo los planes con la frecuencia anterior se extienden 8 semanas. */
  private assertCanExtend(plan: DeliveryPlan): PlanFrequency {
    if (plan.status === PlanStatus.CANCELLED) {
      throw new BadRequestException(PLAN_ALREADY_CANCELLED);
    }
    const frequency = plan.frequency;
    if (!frequency) {
      throw new BadRequestException(RULE_PLAN_NOT_EXTENDED);
    }
    if (frequency === PlanFrequency.ONCE) {
      throw new BadRequestException(ONCE_IS_NOT_EXTENDED);
    }
    if (!renewalDue({ ...plan, frequency }, todayInColombia())) {
      throw new BadRequestException(PLAN_NOT_READY_TO_EXTEND);
    }
    return frequency;
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
      schedule: scheduleOf(plan),
      paused: plan.paused ?? false,
      windowMinutes: plan.deliveryTime ? SLOT_MS / 60_000 : null,
      prescriptionValidUntil: plan.prescriptionValidUntil ?? null,
      renewalDue: plan.frequency
        ? renewalDue({ ...plan, frequency: plan.frequency }, todayInColombia())
        : false,
      createdAt: plan.createdAt,
    };
  }

  private toPublicOrder(order: Order) {
    return presentOrder(order);
  }
}

/** Las columnas del plan que guardan la regla de calendario. */
function scheduleColumns(schedule: PlanSchedule) {
  return {
    scheduleKind: schedule.kind,
    daysOfWeek: schedule.daysOfWeek,
    everyWeeks: schedule.everyWeeks,
    dayOfMonth: schedule.dayOfMonth,
    scheduleDates: schedule.dates,
    occurrenceCount: schedule.count,
    deliveryTime: schedule.time,
  };
}

/** La regla del plan; los planes anteriores a ella la derivan de la frecuencia. */
function scheduleOf(plan: DeliveryPlan): PlanSchedule {
  if (!plan.scheduleKind) {
    return legacySchedule(
      plan.frequency as PlanFrequency,
      plan.startDate,
      plan.windowEndsOn,
    );
  }
  return {
    kind: plan.scheduleKind,
    startDate: plan.startDate,
    endDate:
      plan.occurrenceCount != null
        ? null
        : addCalendarDays(plan.windowEndsOn, -1),
    count: plan.occurrenceCount,
    daysOfWeek: plan.daysOfWeek ?? [],
    everyWeeks: plan.everyWeeks ?? 1,
    dayOfMonth: plan.dayOfMonth,
    dates: plan.scheduleDates ?? [],
    time: plan.deliveryTime,
  };
}

/**
 * Se rehace al cambiar el calendario: sigue en recibido, sin dron ni
 * reintento, y su franja empieza en más de 2 horas.
 */
function isReplaceable(order: Order, now: Date): boolean {
  if (
    !NOT_YET_AUTHORIZED.includes(order.status) ||
    order.droneId ||
    order.fallbackKind
  ) {
    return false;
  }
  const start =
    order.scheduledAt ??
    (order.scheduledFor ? slotFor(order.scheduledFor, null).scheduledAt : null);
  return start != null && start.getTime() - now.getTime() >= SCHEDULE_LEAD_MS;
}

function presentOccurrence(occurrence: Occurrence) {
  return {
    date: occurrence.date,
    scheduledAt: occurrence.scheduledAt,
    windowEndsAt: occurrence.windowEndsAt,
  };
}
