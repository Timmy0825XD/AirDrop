import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { TelemetryAccessService } from './telemetry-access.service';
import { TelemetryController } from './telemetry.controller';
import { TelemetryGateway } from './telemetry.gateway';
import { TelemetryPublisher } from './telemetry.publisher';
import { TelemetryRedis } from './telemetry.redis';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, User]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'),
      }),
    }),
  ],
  controllers: [TelemetryController],
  providers: [
    TelemetryRedis,
    TelemetryPublisher,
    TelemetryAccessService,
    TelemetryGateway,
  ],
  exports: [TelemetryPublisher],
})
export class TelemetryModule {}
