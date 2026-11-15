import { randomUUID } from 'node:crypto';
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { simClock } from '../common/clock/sim-clock';
import { LngLat } from '../routing/routing.rules';
import { FlightClockService } from '../simulation/flight-clock.service';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { isControlEnabled } from './control.rules';
import { Random, pickOne } from './sim-actors.rules';
import { TimelineService } from './timeline.service';
import {
  REGION_CENTER,
  UnidentifiedContact,
  contactPosition,
  contactSpeedKmh,
  crossingThrough,
  nearCorridor,
} from './unidentified.rules';

/** Cada cuánto (ms simulados) se mueve el contacto en el radar. */
const MOVE_EVERY_MS = 5_000;

export type UnidentifiedContactJson = {
  id: string;
  latitude: number;
  longitude: number;
  from: LngLat;
  to: LngLat;
  speedKmh: number;
  startedAt: string;
  endsAt: string;
  /** Matrícula del dron propio cuyo corredor tiene a menos de 1 km. */
  nearIdentifier: string | null;
};

/**
 * RF-36 y RF-48: un contacto sin identificación remota que cruza la región.
 * El radar lo muestra distinto y avisa si pasa cerca de un corredor activo;
 * el sistema no hace nada contra él. Vive en memoria: el reinicio lo borra.
 */
@Injectable()
export class UnidentifiedContactsService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(UnidentifiedContactsService.name);
  private readonly contacts = new Map<string, UnidentifiedContact>();
  private timer: NodeJS.Timeout | null = null;
  /** Los tests lo cambian por uno fijo. */
  random: Random = Math.random;

  constructor(
    private readonly config: ConfigService,
    private readonly flights: FlightClockService,
    private readonly publisher: TelemetryPublisher,
    private readonly timeline: TimelineService,
  ) {}

  onModuleInit(): void {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      return;
    }
    this.timer = simClock.every(MOVE_EVERY_MS, () => {
      void this.move();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * Lanza un contacto. Sin `from` y `to`, cruza por el corredor de un dron en
   * el aire (o por el centro de la región, si no vuela ninguno).
   */
  async launch(input: {
    durationMin: number;
    from?: LngLat;
    to?: LngLat;
  }): Promise<UnidentifiedContactJson> {
    const path =
      input.from && input.to
        ? { from: input.from, to: input.to }
        : crossingThrough(this.crossingPoint(), this.random);
    const startedAtMs = simClock.nowMs();
    const contact: UnidentifiedContact = {
      id: randomUUID(),
      ...path,
      startedAtMs,
      endsAtMs: startedAtMs + input.durationMin * 60_000,
      nearIdentifier: null,
    };
    this.contacts.set(contact.id, contact);
    const view = this.present(contact, startedAtMs);
    await this.publisher.publish({
      type: 'unidentified',
      action: 'started',
      contact: view,
    });
    return view;
  }

  /** CU-38: la consola lo lanza y la línea de tiempo lo cuenta. */
  async launchFromConsole(input: {
    durationMin: number;
    from?: LngLat;
    to?: LngLat;
  }): Promise<UnidentifiedContactJson> {
    const contact = await this.launch(input);
    await this.timeline.recordConsole(
      'Dron no identificado',
      `Cruza la región por ${input.durationMin} min, a ${contact.speedKmh} km/h.`,
    );
    return contact;
  }

  list(): UnidentifiedContactJson[] {
    const now = simClock.nowMs();
    return [...this.contacts.values()].map((contact) =>
      this.present(contact, now),
    );
  }

  /** RF-40: el reinicio no deja contactos en el aire. */
  async clear(): Promise<void> {
    const now = simClock.nowMs();
    for (const contact of this.contacts.values()) {
      await this.publisher.publish({
        type: 'unidentified',
        action: 'ended',
        contact: this.present(contact, now),
      });
    }
    this.contacts.clear();
  }

  async move(now = simClock.nowMs()): Promise<void> {
    const corridors = this.flights.activeCorridors();
    for (const contact of [...this.contacts.values()]) {
      try {
        await this.moveOne(contact, now, corridors);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'contacto';
        this.logger.warn(`No se pudo mover el contacto: ${message}`);
      }
    }
  }

  private async moveOne(
    contact: UnidentifiedContact,
    now: number,
    corridors: ReturnType<FlightClockService['activeCorridors']>,
  ): Promise<void> {
    if (now >= contact.endsAtMs) {
      this.contacts.delete(contact.id);
      await this.publisher.publish({
        type: 'unidentified',
        action: 'ended',
        contact: this.present(contact, now),
      });
      return;
    }
    const position = contactPosition(contact, now);
    const near = nearCorridor(position, corridors);
    const nearIdentifier = near?.identifier ?? null;
    if (near && near.identifier !== contact.nearIdentifier) {
      // RF-36: avisa una vez por corredor; no hay nada que hacerle.
      await this.timeline.recordAlert(
        'Dron no identificado cerca de un corredor',
        `A menos de 1 km del corredor de ${near.identifier}. AirDrop no actúa contra él.`,
        { position, droneId: near.droneId },
      );
    }
    contact.nearIdentifier = nearIdentifier;
    await this.publisher.publish({
      type: 'unidentified',
      action: 'moved',
      contact: this.present(contact, now),
    });
  }

  private crossingPoint(): LngLat {
    const corridors = this.flights.activeCorridors();
    if (!corridors.length) {
      return REGION_CENTER;
    }
    const { coordinates } = pickOne(corridors, this.random);
    const [longitude, latitude] =
      coordinates[Math.floor(coordinates.length / 2)];
    return { latitude, longitude };
  }

  private present(
    contact: UnidentifiedContact,
    now: number,
  ): UnidentifiedContactJson {
    const position = contactPosition(contact, now);
    return {
      id: contact.id,
      latitude: position.latitude,
      longitude: position.longitude,
      from: contact.from,
      to: contact.to,
      speedKmh: contactSpeedKmh(contact),
      startedAt: new Date(contact.startedAtMs).toISOString(),
      endsAt: new Date(contact.endsAtMs).toISOString(),
      nearIdentifier: contact.nearIdentifier,
    };
  }
}
