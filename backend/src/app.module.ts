import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { alignSprintSchema } from './database/align-sprint-schema';
import { ensurePrescriptionBucket } from './database/ensure-prescription-bucket';
import { enablePostgis } from './database/enable-postgis';
import { removeRetiredUserRoles } from './database/remove-retired-user-roles';
import { typeOrmOptions } from './database/typeorm.config';
import { DecisionModule } from './decision/decision.module';
import { DeliveryModule } from './delivery/delivery.module';
import { FleetModule } from './fleet/fleet.module';
import { NotificationsModule } from './notifications/notifications.module';
import { SimulationModule } from './simulation/simulation.module';
import { TelemetryModule } from './telemetry/telemetry.module';
import { GeofencesModule } from './geofences/geofences.module';
import { HubsModule } from './hubs/hubs.module';
import { InventoryModule } from './inventory/inventory.module';
import { OrdersModule } from './orders/orders.module';
import { RoutingModule } from './routing/routing.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot({
      throttlers: [{ ttl: 60000, limit: 60 }],
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: async (config: ConfigService) => {
        const options = typeOrmOptions(config);
        await enablePostgis(options);
        await removeRetiredUserRoles(options);
        await alignSprintSchema(options);
        await ensurePrescriptionBucket(options);
        return options;
      },
    }),
    UsersModule,
    AuthModule,
    HubsModule,
    InventoryModule,
    FleetModule,
    GeofencesModule,
    RoutingModule,
    TelemetryModule,
    NotificationsModule,
    SimulationModule,
    DecisionModule,
    OrdersModule,
    DeliveryModule,
  ],
})
export class AppModule {}
