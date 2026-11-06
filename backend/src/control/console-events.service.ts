import { Injectable } from '@nestjs/common';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import {
  GeofencesService,
  NewTemporaryGeofence,
} from '../geofences/geofences.service';
import { HubOutageService } from '../hubs/hub-outage.service';
import { FlightClockService } from '../simulation/flight-clock.service';
import {
  NewWeatherCell,
  WeatherService,
  presentWeatherCell,
} from '../weather/weather.service';

/**
 * CU-38: los eventos que lanza la consola. Solo los entrega a su dominio
 * (clima, geovallas temporales, incidentes de dron, apagones) y avisa al reloj de vuelo si cambió lo que no se puede
 * cruzar. La respuesta a cada evento la deciden las reglas de ese dominio.
 */
@Injectable()
export class ConsoleEventsService {
  constructor(
    private readonly weather: WeatherService,
    private readonly flights: FlightClockService,
    private readonly geofences: GeofencesService,
    private readonly outages: HubOutageService,
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

  listGeofences() {
    return this.geofences.listTemporary();
  }

  /** RF-36: el servicio de geovallas ya revisa los vuelos en el aire (RF-33). */
  createGeofence(userId: string, input: NewTemporaryGeofence) {
    return this.geofences.createTemporary(userId, input);
  }

  endGeofence(id: string) {
    return this.geofences.endTemporary(id);
  }

  listOutages() {
    return this.outages.active();
  }

  /** RF-36: la reubicación de sus pedidos la hace el motor de decisión. */
  startOutage(hubId: string, durationMin: number) {
    return this.outages.start(hubId, durationMin);
  }

  endOutage(hubId: string) {
    return this.outages.end(hubId);
  }

  /** RF-34: lo aplica el reloj de vuelo, que es quien mueve al dron. */
  launchIncident(droneId: string, kind: IncidentKind) {
    return this.flights.launchIncident(droneId, kind);
  }
}
