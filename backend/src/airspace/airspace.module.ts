import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Geofence } from '../geofences/geofence.entity';
import { AuthModule } from '../auth/auth.module';
import { AirspaceController } from './airspace.controller';
import { AirspaceService } from './airspace.service';
import { TerrainService } from './terrain.service';

@Module({
  imports: [AuthModule, TypeOrmModule.forFeature([Geofence])],
  controllers: [AirspaceController],
  providers: [AirspaceService, TerrainService],
  exports: [AirspaceService, TerrainService],
})
export class AirspaceModule {}
