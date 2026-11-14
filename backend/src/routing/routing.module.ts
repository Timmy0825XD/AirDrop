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
  exports: [RoutePlannerService],
})
export class RoutingModule {}
