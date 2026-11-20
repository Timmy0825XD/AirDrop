import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SimulationModule } from '../simulation/simulation.module';
import { AuthModule } from '../auth/auth.module';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { Hub } from '../hubs/hub.entity';
import { AirspaceModule } from '../airspace/airspace.module';
import { Geofence } from './geofence.entity';
import { GeofenceChange } from './geofence-change.entity';
import { LegalZonesController } from './legal-zones.controller';
import { LegalZonesService } from './legal-zones.service';
import { GeofencesController } from './geofences.controller';
import { GeofencesService } from './geofences.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Geofence, GeofenceChange, Hub]),
    AirspaceModule,
    AuthModule,
    SimulationModule,
    TelemetryModule,
  ],
  controllers: [LegalZonesController, GeofencesController],
  providers: [GeofencesService, LegalZonesService],
  exports: [GeofencesService],
})
export class GeofencesModule {}
