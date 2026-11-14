import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AirspaceController } from './airspace.controller';
import { AirspaceService } from './airspace.service';
import { DaylightService } from './daylight.service';
import { TerrainService } from './terrain.service';

@Module({
  imports: [AuthModule],
  controllers: [AirspaceController],
  providers: [AirspaceService, TerrainService, DaylightService],
  exports: [AirspaceService, TerrainService, DaylightService],
})
export class AirspaceModule {}
