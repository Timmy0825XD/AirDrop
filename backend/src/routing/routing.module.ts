import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WeatherModule } from '../weather/weather.module';
import { MissionRoute } from './mission-route.entity';
import { RoutePlannerService } from './route-planner.service';

@Module({
  imports: [TypeOrmModule.forFeature([MissionRoute]), WeatherModule],
  providers: [RoutePlannerService],
  exports: [RoutePlannerService],
})
export class RoutingModule {}
