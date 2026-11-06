import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TelemetryModule } from '../telemetry/telemetry.module';
import { WeatherCell } from './weather-cell.entity';
import { WeatherService } from './weather.service';

/**
 * RF-32: clima simulado. Lo leen Decision (¿se puede volar?), Routing (las
 * tormentas como geovallas) y Simulation (viento y lluvia en cada tick).
 */
@Module({
  imports: [TypeOrmModule.forFeature([WeatherCell]), TelemetryModule],
  providers: [WeatherService],
  exports: [WeatherService],
})
export class WeatherModule {}
