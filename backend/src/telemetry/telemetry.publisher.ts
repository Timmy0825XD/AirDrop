import { Injectable, OnModuleInit } from '@nestjs/common';
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
