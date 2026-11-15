import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AirspaceController } from './airspace.controller';
import { AirspaceService } from './airspace.service';

@Module({
  imports: [AuthModule],
  controllers: [AirspaceController],
  providers: [AirspaceService],
  exports: [AirspaceService],
})
export class AirspaceModule {}
