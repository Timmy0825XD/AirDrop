import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { QuarantineRecord } from '../inventory/quarantine-record.entity';
import { Order } from '../orders/order.entity';
import { RoutingModule } from '../routing/routing.module';
import { Mission } from '../simulation/mission.entity';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { RadarController } from './radar.controller';
import { RadarService } from './radar.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Hub,
      Drone,
      Order,
      Mission,
      InventoryItem,
      QuarantineRecord,
    ]),
    RoutingModule,
    TelemetryModule,
  ],
  controllers: [RadarController],
  providers: [RadarService],
})
export class RadarModule {}
