import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { TelemetryRedis } from '../telemetry/telemetry.redis';
import { isControlEnabled } from './control.rules';
import {
  ACTORS_OFF,
  ACTORS_STATE_KEY,
  ActorsChange,
  ActorsState,
  actorsChangeText,
  applyActorsChange,
  parseActorsState,
} from './sim-actors.rules';
import { TimelineService } from './timeline.service';

/**
 * RF-37: los interruptores de los actores simulados (despachador automático
 * y flujo continuo de pedidos). Viven en Redis para sobrevivir a un reinicio
 * del backend y se publican en la sala del radar. No actúan: solo dicen si
 * cada actor está encendido.
 */
@Injectable()
export class SimActorsService implements OnModuleInit {
  private readonly logger = new Logger(SimActorsService.name);
  private state: ActorsState = { ...ACTORS_OFF };

  constructor(
    private readonly config: ConfigService,
    private readonly redis: TelemetryRedis,
    private readonly publisher: TelemetryPublisher,
    private readonly timeline: TimelineService,
  ) {}

  /** Con la consola apagada los actores no existen, haya lo que haya en Redis. */
  async onModuleInit(): Promise<void> {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    try {
      this.state = parseActorsState(await this.redis.read(ACTORS_STATE_KEY));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Redis';
      this.logger.warn(`No se pudieron leer los actores: ${message}`);
    }
  }

  view(): ActorsState {
    return { ...this.state };
  }

  async change(change: ActorsChange): Promise<ActorsState> {
    const before = this.state;
    this.state = applyActorsChange(before, change);
    await this.saveAndPublish();
    for (const line of actorsChangeText(before, this.state)) {
      await this.timeline.recordConsole(line, null);
    }
    return this.view();
  }

  /** RF-40: el reinicio apaga los actores, sin contarlo en la línea nueva. */
  async turnOff(): Promise<void> {
    this.state = { ...ACTORS_OFF };
    await this.saveAndPublish();
  }

  private async saveAndPublish(): Promise<void> {
    await this.redis.write(ACTORS_STATE_KEY, JSON.stringify(this.state));
    await this.publisher.publish({ type: 'actors', actors: this.view() });
  }
}
