import { Injectable, OnModuleInit } from '@nestjs/common';
import { ClockView } from '../common/clock/clock.rules';
import type { ChaosIntensity } from '../control/chaos.rules';
import type { ActorsState } from '../control/sim-actors.rules';
import type { TimelineEntry } from '../control/timeline.rules';
import type { WeatherCellJson } from '../weather/weather.service';
import type { TemporaryGeofenceJson } from '../geofences/geofences.service';
import type { IncidentJson } from '../simulation/flight-incidents.service';
import type { HubOutageJson } from '../hubs/hub-outage.service';
import { OrderStatus } from '../common/enums/order-status.enum';
import { FlightAlertKind, LiveFlight } from '../simulation/simulation.rules';
import {
  TELEMETRY_CHANNEL,
  TelemetryRedis,
  telemetryKey,
} from './telemetry.redis';

export type TelemetryEvent =
  | { type: 'telemetry'; orderId: string; flight: LiveFlight }
  | { type: 'order-status'; orderId: string; status: OrderStatus }
  | { type: 'queue-changed'; hubId: string; orderId: string }
  /** RF-31: cambió la velocidad o la pausa del reloj simulado. */
  | { type: 'clock'; clock: ClockView }
  /** RF-39: un paso del flujo contado para la consola. */
  | { type: 'timeline'; entry: TimelineEntry }
  /** RF-38: se encendió, se apagó o cambió de intensidad el modo caos. */
  | { type: 'chaos'; chaos: { enabled: boolean; intensity: ChaosIntensity } }
  /** RF-37: se encendió o se apagó un actor simulado. */
  | { type: 'actors'; actors: ActorsState }
  /** RF-40: el escenario volvió a la semilla; el radar recarga todo. */
  | { type: 'scenario-reset' }
  /** RF-32: empezó o terminó una celda de clima. */
  | { type: 'weather'; action: 'created' | 'ended'; cell: WeatherCellJson }
  /** RF-36: empezó o terminó una geovalla temporal. */
  | {
      type: 'geofence';
      action: 'created' | 'ended';
      geofence: TemporaryGeofenceJson;
    }
  /** RF-36: una central se quedó sin energía, o le volvió. */
  | {
      type: 'hub-outage';
      action: 'started' | 'ended';
      outage: HubOutageJson;
    }
  /** RF-34: un incidente en vuelo nuevo, o un cambio en cómo va. */
  | { type: 'incident'; incident: IncidentJson }
  /** RF-33: una zona nueva cruzaba el tramo que le faltaba al dron. */
  | {
      type: 'rerouted';
      orderId: string;
      droneId: string;
      outcome: 'rerouted' | 'blocked';
      addedKm: number | null;
      crossesGeofence: boolean;
      /** Por el tramo nuevo no le alcanza para terminar con la reserva. */
      batteryShort: boolean;
    }
  | {
      type: 'alert';
      orderId: string;
      droneId: string;
      kind: FlightAlertKind;
      message: string;
    };

@Injectable()
export class TelemetryPublisher implements OnModuleInit {
  private readonly handlers: Array<(event: TelemetryEvent) => void> = [];

  constructor(private readonly redis: TelemetryRedis) {}

  onModuleInit(): void {
    this.redis.listen((raw) => {
      let event: TelemetryEvent;
      try {
        event = JSON.parse(raw) as TelemetryEvent;
      } catch {
        return;
      }
      for (const handler of this.handlers) {
        handler(event);
      }
    });
  }

  isReady(): boolean {
    return this.redis.isReady();
  }

  onEvent(handler: (event: TelemetryEvent) => void): void {
    this.handlers.push(handler);
  }

  async publishFlight(flight: LiveFlight): Promise<void> {
    await this.redis.write(
      telemetryKey(flight.orderId),
      JSON.stringify(flight),
    );
    await this.publish({
      type: 'telemetry',
      orderId: flight.orderId,
      flight,
    });
  }

  /**
   * RF-35: el pedido vuelve a despacharse. El vuelo del dron anterior no
   * debe retomarse con el dron nuevo.
   */
  async forgetFlight(orderId: string): Promise<void> {
    await this.redis.remove([telemetryKey(orderId)]);
  }

  async readFlight(orderId: string): Promise<LiveFlight | null> {
    const raw = await this.redis.read(telemetryKey(orderId));
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as LiveFlight;
  }

  async publish(event: TelemetryEvent): Promise<void> {
    await this.redis.publish(TELEMETRY_CHANNEL, JSON.stringify(event));
  }
}
