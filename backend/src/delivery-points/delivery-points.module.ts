import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AirspaceModule } from '../airspace/airspace.module';
import { AuthModule } from '../auth/auth.module';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { DeliveryPoint } from './delivery-point.entity';
import { DeliveryPointsController } from './delivery-points.controller';
import { DeliveryPointsService } from './delivery-points.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([DeliveryPoint, Hub, InventoryItem]),
    AuthModule,
    AirspaceModule,
  ],
  controllers: [DeliveryPointsController],
  providers: [DeliveryPointsService],
  exports: [DeliveryPointsService],
})
export class DeliveryPointsModule {}
