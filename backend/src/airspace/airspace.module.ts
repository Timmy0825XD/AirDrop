import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AirspaceController } from './airspace.controller';
import { AirspaceService } from './airspace.service';
import { TerrainService } from './terrain.service';

@Module({
  imports: [AuthModule],
  controllers: [AirspaceController],
  providers: [AirspaceService, TerrainService],
  exports: [AirspaceService, TerrainService],
})
export class AirspaceModule {}
