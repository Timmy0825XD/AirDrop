import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { DecisionModule } from '../decision/decision.module';
import { Hub } from '../hubs/hub.entity';
import { HubsModule } from '../hubs/hubs.module';
import { Drone } from '../fleet/drone.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { RoutingModule } from '../routing/routing.module';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { DeliveryPlan } from './delivery-plan.entity';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { PlanAgendaService } from './plan-agenda.service';
import { PlanOccurrencesController } from './plan-occurrences.controller';
import { PlanOccurrencesService } from './plan-occurrences.service';
import { PlanRemindersService } from './plan-reminders.service';
import { PlanWindowService } from './plan-window.service';
import { PrescriptionImage } from './prescription-image.entity';
import { PrescriptionStorage } from './prescription-storage';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Order,
      PrescriptionImage,
      DeliveryPlan,
      InventoryItem,
      Hub,
      Drone,
    ]),
    AuthModule,
    HubsModule,
    DecisionModule,
    NotificationsModule,
    RoutingModule,
  ],
  controllers: [OrdersController, PlanOccurrencesController],
  providers: [
    OrdersService,
    InventoryOfferQuery,
    PrescriptionStorage,
    PlanOccurrencesService,
    PlanRemindersService,
    PlanWindowService,
    PlanAgendaService,
  ],
})
export class OrdersModule {}
