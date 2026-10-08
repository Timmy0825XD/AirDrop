import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { DecisionModule } from '../decision/decision.module';
import { Hub } from '../hubs/hub.entity';
import { HubsModule } from '../hubs/hubs.module';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { DeliveryPlan } from './delivery-plan.entity';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { PrescriptionImage } from './prescription-image.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Order,
      PrescriptionImage,
      DeliveryPlan,
      InventoryItem,
      Hub,
    ]),
    AuthModule,
    HubsModule,
    DecisionModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService, InventoryOfferQuery],
})
export class OrdersModule {}
