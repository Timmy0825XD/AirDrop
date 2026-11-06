import { Injectable } from '@nestjs/common';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import { FlightClockService } from '../simulation/flight-clock.service';
import {
  NewWeatherCell,
  WeatherService,
  presentWeatherCell,
} from '../weather/weather.service';

/**
 * CU-38: los eventos que lanza la consola. Solo los entrega a su dominio
 * (aquí, el clima) y avisa al reloj de vuelo si cambió lo que no se puede
 * cruzar. La respuesta a cada evento la deciden las reglas de ese dominio.
 */
@Injectable()
export class ConsoleEventsService {
  constructor(
    private readonly weather: WeatherService,
    private readonly flights: FlightClockService,
  ) {}

  listWeather() {
    return this.weather.active().map(presentWeatherCell);
  }

  async createWeather(userId: string, input: NewWeatherCell) {
    const cell = await this.weather.create(userId, input);
    if (cell.kind === WeatherKind.STORM) {
      // RF-33: la tormenta puede cruzar el tramo que le falta a un dron.
      await this.flights.recheckRoutes();
    }
    return presentWeatherCell(cell);
  }

  async endWeather(id: string) {
    return presentWeatherCell(await this.weather.end(id));
  }
}
