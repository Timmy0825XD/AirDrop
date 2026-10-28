import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { HubsModule } from '../hubs/hubs.module';
import { Order } from '../orders/order.entity';
import { InventoryItem } from './inventory-item.entity';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { QuarantineRecord } from './quarantine-record.entity';
import { RestockController } from './restock.controller';
import { RestockService } from './restock.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([InventoryItem, Order, QuarantineRecord]),
    AuthModule,
    HubsModule,
  ],
  controllers: [InventoryController, RestockController],
  providers: [InventoryService, RestockService],
  exports: [InventoryService, RestockService],
})
export class InventoryModule {}
