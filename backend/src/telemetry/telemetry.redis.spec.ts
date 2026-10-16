import { ConfigService } from '@nestjs/config';
import { TELEMETRY_CHANNEL, TelemetryRedis } from './telemetry.redis';

/** Redis falso: la conexión del suscriptor reparte lo que se publica. */
class FakeRedis {
  static subscribers: FakeRedis[] = [];
  private listeners: Array<(channel: string, message: string) => void> = [];
  private channels = new Set<string>();

  connect = jest.fn(() => Promise.resolve());
  ping = jest.fn(() => Promise.resolve('PONG'));
  disconnect = jest.fn();

  on(event: string, listener: (channel: string, message: string) => void) {
    if (event === 'message') {
      this.listeners.push(listener);
    }
    return this;
  }

  duplicate() {
    const subscriber = new FakeRedis();
    FakeRedis.subscribers.push(subscriber);
    return subscriber;
  }

  subscribe(channel: string) {
    this.channels.add(channel);
    return Promise.resolve(1);
  }

  publish(channel: string, message: string) {
    for (const subscriber of FakeRedis.subscribers) {
      if (!subscriber.channels.has(channel)) {
        continue;
      }
      for (const listener of subscriber.listeners) {
        listener(channel, message);
      }
    }
    return Promise.resolve(1);
  }
}

// Getter: jest.mock sube sobre la clase, que se busca recién al conectar.
jest.mock('ioredis', () => ({
  get Redis() {
    return FakeRedis;
  },
}));

function build() {
  const config = {
    get: () => 'redis://localhost:6379',
  } as unknown as ConfigService;
  return new TelemetryRedis(config);
}

describe('TelemetryRedis', () => {
  beforeEach(() => {
    FakeRedis.subscribers = [];
  });

  it('delivers events to a listener registered while it is still connecting', async () => {
    const redis = build();
    const received: string[] = [];

    // Nest corre los onModuleInit del módulo en paralelo: el publisher
    // escucha antes de que Redis termine de conectar.
    const connecting = redis.onModuleInit();
    redis.listen((message) => received.push(message));
    await connecting;

    await redis.publish(TELEMETRY_CHANNEL, '{"type":"telemetry"}');

    expect(redis.isReady()).toBe(true);
    expect(received).toEqual(['{"type":"telemetry"}']);
  });

  it('ignores other channels', async () => {
    const redis = build();
    const received: string[] = [];
    await redis.onModuleInit();
    redis.listen((message) => received.push(message));

    await redis.publish('otro:canal', 'nada');

    expect(received).toEqual([]);
  });
});
