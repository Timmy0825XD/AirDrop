import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Hub } from './hub.entity';
import { HubsController } from './hubs.controller';
import { HubsService } from './hubs.service';

@Module({
  imports: [TypeOrmModule.forFeature([Hub]), AuthModule],
  controllers: [HubsController],
  providers: [HubsService],
  exports: [HubsService],
})
export class HubsModule {}
