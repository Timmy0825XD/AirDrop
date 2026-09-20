import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { enablePostgis } from './database/enable-postgis';
import { removeRetiredUserRoles } from './database/remove-retired-user-roles';
import { typeOrmOptions } from './database/typeorm.config';
import { FleetModule } from './fleet/fleet.module';
import { GeofencesModule } from './geofences/geofences.module';
import { HubsModule } from './hubs/hubs.module';
import { InventoryModule } from './inventory/inventory.module';
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
        return options;
      },
    }),
    UsersModule,
    AuthModule,
    HubsModule,
    InventoryModule,
    FleetModule,
    GeofencesModule,
  ],
})
export class AppModule {}
