import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ClockChange,
  ClockView,
  parseClockState,
} from '../common/clock/clock.rules';
import { simClock } from '../common/clock/sim-clock';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { TelemetryRedis } from '../telemetry/telemetry.redis';
import { CLOCK_STATE_KEY, isControlEnabled } from './control.rules';

/**
 * RF-31: cambia la velocidad del reloj simulado, la guarda en Redis para que
 * sobreviva a un reinicio del backend y la publica por el socket. No decide
 * nada del negocio: solo mueve el reloj.
 */
@Injectable()
export class ClockControlService implements OnModuleInit {
  private readonly logger = new Logger(ClockControlService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly redis: TelemetryRedis,
    private readonly publisher: TelemetryPublisher,
  ) {}

  /** Con la consola apagada el reloj es el real, haya lo que haya en Redis. */
  async onModuleInit(): Promise<void> {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    try {
      const saved = parseClockState(await this.redis.read(CLOCK_STATE_KEY));
      if (saved) {
        simClock.restore(saved);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Redis';
      this.logger.warn(`No se pudo leer el reloj guardado: ${message}`);
    }
  }

  view(): ClockView {
    return simClock.view();
  }

  async change(change: ClockChange): Promise<ClockView> {
    const state = simClock.change(change);
    await this.redis.write(CLOCK_STATE_KEY, JSON.stringify(state));
    const view = simClock.view();
    await this.publisher.publish({ type: 'clock', clock: view });
    return view;
  }
}
