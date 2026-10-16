import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

export const TELEMETRY_CHANNEL = 'telemetry:events';

export function telemetryKey(orderId: string): string {
  return `telemetry:order:${orderId}`;
}

@Injectable()
export class TelemetryRedis implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(TelemetryRedis.name);
  private client: Redis | null = null;
  private subscriber: Redis | null = null;
  private ready = false;
  private reported = false;

  /**
   * Quién escucha el canal. Se guarda aparte porque Nest arranca los
   * `onModuleInit` del módulo en paralelo: `TelemetryPublisher` llama
   * [listen] antes de que esta conexión termine de abrir.
   */
  private readonly handlers: Array<(message: string) => void> = [];

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const url = this.config.get<string>('REDIS_URL');
    if (!url) {
      this.fail('Falta REDIS_URL. El reloj de vuelo no arranca.');
      return;
    }
    const options = {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      connectTimeout: 2_000,
      enableOfflineQueue: false,
      retryStrategy: () => null,
    };
    this.client = new Redis(url, options);
    this.client.on('error', () => {
      this.fail('Redis no conecta. El reloj de vuelo no arranca.');
    });
    try {
      await this.client.connect();
      await this.client.ping();
      this.subscriber = this.client.duplicate();
      this.subscriber.on('error', () => {
        this.fail('Redis no conecta. El reloj de vuelo no arranca.');
      });
      await this.subscriber.connect();
      this.subscriber.on('message', (channel, message) => {
        if (channel !== TELEMETRY_CHANNEL) {
          return;
        }
        for (const handler of this.handlers) {
          handler(message);
        }
      });
      await this.subscriber.subscribe(TELEMETRY_CHANNEL);
      this.ready = true;
    } catch {
      this.fail('Redis no conecta. El reloj de vuelo no arranca.');
      this.disconnect();
    }
  }

  onModuleDestroy(): void {
    this.disconnect();
  }

  isReady(): boolean {
    return this.ready;
  }

  async write(key: string, value: string): Promise<void> {
    await this.client?.set(key, value);
  }

  async read(key: string): Promise<string | null> {
    return (await this.client?.get(key)) ?? null;
  }

  async publish(channel: string, message: string): Promise<void> {
    await this.client?.publish(channel, message);
  }

  /** Sirve antes o después de conectar: el canal se suscribe al abrir. */
  listen(handler: (message: string) => void): void {
    this.handlers.push(handler);
  }

  private fail(message: string): void {
    this.ready = false;
    if (this.reported) {
      return;
    }
    this.reported = true;
    this.logger.error(message);
  }

  private disconnect(): void {
    this.ready = false;
    this.subscriber?.disconnect();
    this.client?.disconnect();
    this.subscriber = null;
    this.client = null;
  }
}
