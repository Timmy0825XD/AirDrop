import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryModule } from '../inventory/inventory.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { SimulationModule } from '../simulation/simulation.module';
import { DeliveryCode } from './delivery-code.entity';
import { DeliveryController } from './delivery.controller';
import { DeliveryService } from './delivery.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([DeliveryCode]),
    NotificationsModule,
    SimulationModule,
    InventoryModule,
  ],
  controllers: [DeliveryController],
  providers: [DeliveryService],
})
export class DeliveryModule {}
