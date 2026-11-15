import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AirspaceModule } from '../airspace/airspace.module';
import { WeatherModule } from '../weather/weather.module';
import { MissionRoute } from './mission-route.entity';
import { RoutePlannerService } from './route-planner.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([MissionRoute]),
    WeatherModule,
    AirspaceModule,
  ],
  providers: [RoutePlannerService],
  // Quien planea rutas también necesita las zonas y el terreno (RF-43, RF-46).
  exports: [RoutePlannerService, AirspaceModule],
})
export class RoutingModule {}
