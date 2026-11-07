import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { HubStatus } from '../common/enums/hub-status.enum';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { isPowered } from '../hubs/hub-power.rules';
import {
  AirborneDrone,
  FlightClockService,
} from '../simulation/flight-clock.service';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { TelemetryRedis } from '../telemetry/telemetry.redis';
import {
  CHAOS_OFF,
  CHAOS_STATE_KEY,
  CHAOS_SWEEP_MS,
  ChaosChange,
  ChaosEvent,
  ChaosState,
  applyChaosChange,
  chaosChangeText,
  chaosOutageMinutes,
  chaosSurgeCount,
  chaosTitle,
  chaosWeather,
  circlePolygon,
  nextChaosAt,
  parseChaosState,
  pickDuration,
  pickEvent,
  pickFamily,
  pickWornDrone,
} from './chaos.rules';
import { ConsoleEventsService } from './console-events.service';
import { isControlEnabled } from './control.rules';
import { simulatedDestinations } from './demo-scenario';
import { OrderGeneratorService } from './order-generator.service';
import { Random, pickOne } from './sim-actors.rules';
import { SimulatedReceiverService } from './simulated-receiver.service';
import { TimelineService } from './timeline.service';

type Point = { latitude: number; longitude: number };

/** Lo que dejó el evento, para contarlo en la línea de tiempo. */
type Outcome = {
  detail: string | null;
  position: Point | null;
  droneId?: string;
  hubId?: string;
  orderId?: string;
};

/**
 * RF-38, CU-40: el modo caos. Apagado por defecto. Encendido, cada tanto
 * sortea un evento del catálogo (`chaos.rules.ts`) y lo entrega al mismo
 * servicio que usa la consola; la respuesta la deciden las reglas de cada
 * dominio. Apagarlo no deshace lo que ya corre.
 */
@Injectable()
export class ChaosService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ChaosService.name);
  private state: ChaosState = { ...CHAOS_OFF };
  private nextAt: Date | null = null;
  private timer: NodeJS.Timeout | null = null;
  private running = false;
  /** Los tests lo cambian por uno fijo. */
  random: Random = Math.random;

  constructor(
    private readonly config: ConfigService,
    private readonly redis: TelemetryRedis,
    private readonly publisher: TelemetryPublisher,
    private readonly timeline: TimelineService,
    private readonly events: ConsoleEventsService,
    private readonly flights: FlightClockService,
    private readonly generator: OrderGeneratorService,
    private readonly receiver: SimulatedReceiverService,
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
  ) {}

  async onModuleInit(): Promise<void> {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    try {
      this.state = parseChaosState(await this.redis.read(CHAOS_STATE_KEY));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Redis';
      this.logger.warn(`No se pudo leer el modo caos: ${message}`);
    }
    if (this.state.enabled) {
      this.nextAt = nextChaosAt(
        simClock.now(),
        this.state.intensity,
        this.random,
      );
    }
    this.timer = simClock.every(CHAOS_SWEEP_MS, () => {
      void this.runDue();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  view(): Omit<ChaosState, 'enabledByUserId'> {
    return { enabled: this.state.enabled, intensity: this.state.intensity };
  }

  async change(userId: string, change: ChaosChange) {
    const before = this.state;
    this.state = applyChaosChange(before, change, userId);
    if (!this.state.enabled) {
      this.nextAt = null;
    } else if (!before.enabled || before.intensity !== this.state.intensity) {
      // Al encender, o con otra intensidad, el primer sorteo cuenta desde ahora.
      this.nextAt = nextChaosAt(
        simClock.now(),
        this.state.intensity,
        this.random,
      );
    }
    await this.saveAndPublish();
    const line = chaosChangeText(before, this.state);
    if (line) {
      await this.timeline.recordConsole(line, null);
    }
    return this.view();
  }

  /** RF-40: el reinicio apaga el caos, sin contarlo en la línea nueva. */
  async turnOff(): Promise<void> {
    this.state = { ...CHAOS_OFF };
    this.nextAt = null;
    await this.saveAndPublish();
  }

  async runDue(now = simClock.now()): Promise<void> {
    if (this.running || !this.state.enabled || !this.state.enabledByUserId) {
      return;
    }
    if (this.nextAt && now < this.nextAt) {
      return;
    }
    this.running = true;
    try {
      await this.fire(this.state.enabledByUserId, now);
    } finally {
      this.nextAt = nextChaosAt(now, this.state.intensity, this.random);
      this.running = false;
    }
  }

  /** Sortea y aplica un evento. Si su dominio lo rechaza, se cuenta y sigue. */
  async fire(userId: string, now: Date): Promise<ChaosEvent | null> {
    const airborne = this.flights.airborne();
    const family = pickFamily(this.random, airborne.length > 0);
    const target =
      family === 'drone' || family === 'collision'
        ? await this.wornDrone(airborne)
        : null;
    const event = pickEvent(
      family,
      this.state.intensity,
      now,
      target?.coldLoad ?? false,
      this.random,
    );
    try {
      const outcome = await this.apply(event, userId, airborne, target);
      if (!outcome) {
        return null;
      }
      await this.timeline.recordChaos(chaosTitle(event), outcome.detail, {
        position: outcome.position,
        droneId: outcome.droneId,
        hubId: outcome.hubId,
        orderId: outcome.orderId,
      });
      return event;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'evento';
      this.logger.warn(`El caos no pudo lanzar ${event.kind}: ${message}`);
      return null;
    }
  }

  private async apply(
    event: ChaosEvent,
    userId: string,
    airborne: AirborneDrone[],
    target: AirborneDrone | null,
  ): Promise<Outcome | null> {
    if (event.family === 'weather') {
      const center = this.placeNearFlight(airborne);
      const cell = await this.events.createWeather(
        userId,
        chaosWeather(event.kind, center, this.random),
      );
      return {
        detail: `${cell.radiusKm.toLocaleString('es-CO')} km por ${minutesBetween(cell.startsAt, cell.endsAt)} min`,
        position: center,
      };
    }
    if (event.family === 'drone' || event.family === 'collision') {
      if (!target) {
        return null;
      }
      const incident = await this.events.launchIncident(
        target.droneId,
        event.kind,
      );
      return {
        detail: null,
        position: {
          latitude: incident.latitude,
          longitude: incident.longitude,
        },
        droneId: target.droneId,
        orderId: target.orderId,
      };
    }
    if (event.kind === 'temporary_geofence') {
      const center = this.placeNearFlight(airborne);
      const durationMin = pickDuration(this.random);
      await this.events.createGeofence(userId, {
        name: 'Evento aéreo (caos)',
        reason: 'Zona restringida temporal sorteada por el modo caos.',
        polygon: circlePolygon(center, 0.5 + this.random() * 0.7),
        durationMin,
      });
      return { detail: `Por ${durationMin} min`, position: center };
    }
    if (event.kind === 'surge') {
      const place = pickOne(simulatedDestinations, this.random);
      const result = await this.generator.surge(
        place,
        1,
        chaosSurgeCount(this.random),
      );
      return {
        detail: `${result.created.length} urgencias cerca de ${place.address}`,
        position: { latitude: place.latitude, longitude: place.longitude },
      };
    }
    if (event.kind === 'no_show') {
      const orderId = await this.receiver.markNoShow();
      if (!orderId) {
        return null;
      }
      return {
        detail: 'El receptor no llegará: al aterrizar corren los 5 minutos.',
        position: null,
        orderId,
      };
    }
    const hub = await this.outageTarget();
    if (!hub) {
      return null;
    }
    const minutes = chaosOutageMinutes(this.random);
    await this.events.startOutage(hub.id, minutes);
    return {
      detail: `${hub.name}, por ${minutes} min`,
      position: { latitude: hub.latitude, longitude: hub.longitude },
      hubId: hub.id,
    };
  }

  /** Donde le pesa a alguien: el corredor de un dron en el aire, o un barrio. */
  private placeNearFlight(airborne: AirborneDrone[]): Point {
    if (airborne.length) {
      return pickOne(airborne, this.random).midpoint;
    }
    const place = pickOne(simulatedDestinations, this.random);
    return { latitude: place.latitude, longitude: place.longitude };
  }

  private async wornDrone(
    airborne: AirborneDrone[],
  ): Promise<AirborneDrone | null> {
    if (!airborne.length) {
      return null;
    }
    const rows = await this.drones.find({
      where: { id: In(airborne.map((item) => item.droneId)) },
    });
    const worn = pickWornDrone(rows, this.random);
    return airborne.find((item) => item.droneId === worn?.id) ?? null;
  }

  private async outageTarget(): Promise<Hub | null> {
    const now = simClock.now();
    const hubs = await this.hubs.find({ where: { status: HubStatus.ACTIVE } });
    const powered = hubs.filter((hub) => isPowered(hub, now));
    // Con una sola central encendida, apagarla deja la demo sin nada que ver.
    return powered.length > 1 ? pickOne(powered, this.random) : null;
  }

  private async saveAndPublish(): Promise<void> {
    await this.redis.write(CHAOS_STATE_KEY, JSON.stringify(this.state));
    await this.publisher.publish({ type: 'chaos', chaos: this.view() });
  }
}

function minutesBetween(from: string | Date, to: string | Date): number {
  return Math.round(
    (new Date(to).getTime() - new Date(from).getTime()) / 60_000,
  );
}
