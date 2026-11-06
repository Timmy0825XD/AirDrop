import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SimulationModule } from '../simulation/simulation.module';
import { AuthModule } from '../auth/auth.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { Hub } from '../hubs/hub.entity';
import { Geofence } from './geofence.entity';
import { GeofencesController } from './geofences.controller';
import { GeofencesService } from './geofences.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Geofence, Hub]),
    AuthModule,
    SimulationModule,
    TelemetryModule,
  ],
  controllers: [GeofencesController],
  providers: [GeofencesService],
  exports: [GeofencesService],
})
export class GeofencesModule {}
