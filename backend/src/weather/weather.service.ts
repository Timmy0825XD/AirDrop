import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { WeatherCell } from './weather-cell.entity';
import {
  WeatherCellView,
  activeCells,
  isActive,
  stormPolygons,
} from './weather.rules';

export type NewWeatherCell = {
  kind: WeatherKind;
  latitude: number;
  longitude: number;
  radiusKm: number;
  durationMin: number;
  windSpeedMs?: number;
  windGustMs?: number;
  windFromDeg?: number;
};

export const WIND_NEEDS_SPEED =
  'El viento necesita velocidad (m/s) y de dónde sopla (grados).';
export const GUST_BELOW_SPEED =
  'Las ráfagas no pueden ser más suaves que el viento sostenido.';
export const WEATHER_NOT_FOUND = 'Esa celda de clima no existe.';

/** Cada cuánto (en hora simulada) se mira qué celdas ya pasaron. */
const EXPIRY_SWEEP_MS = 15_000;

/**
 * RF-32: guarda las celdas de clima y responde cuáles rigen ahora. Las tiene
 * en memoria (un solo proceso) porque el reloj de vuelo las lee en cada tick;
 * Postgres las conserva para un reinicio del backend.
 */
@Injectable()
export class WeatherService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(WeatherService.name);
  private cells: WeatherCellView[] = [];
  /** Celdas cuyo final ya se avisó (para contar "la tormenta pasó" una vez). */
  private readonly ended = new Set<string>();
  private timer: NodeJS.Timeout | null = null;

  constructor(
    @InjectRepository(WeatherCell)
    private readonly repo: Repository<WeatherCell>,
    private readonly publisher: TelemetryPublisher,
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      await this.reload();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'clima';
      this.logger.warn(`No se pudo cargar el clima: ${message}`);
    }
    this.timer = simClock.every(EXPIRY_SWEEP_MS, () => {
      void this.announceExpired();
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async reload(): Promise<void> {
    const rows = await this.repo.find();
    this.cells = rows.map(toView);
    const now = simClock.now();
    for (const cell of this.cells) {
      if (now >= cell.endsAt) this.ended.add(cell.id);
    }
  }

  /** Las celdas que rigen en la hora simulada. */
  active(now = simClock.now()): WeatherCellView[] {
    return activeCells(this.cells, now);
  }

  /** RF-12 y RF-32: las tormentas vigentes, como polígonos para rutas. */
  stormPolygons(now = simClock.now()) {
    return stormPolygons(this.active(now));
  }

  async create(
    userId: string,
    input: NewWeatherCell,
  ): Promise<WeatherCellView> {
    assertWeatherInput(input);
    const now = simClock.now();
    const wind = input.kind === WeatherKind.WIND;
    const saved = await this.repo.save(
      this.repo.create({
        kind: input.kind,
        latitude: input.latitude,
        longitude: input.longitude,
        radiusKm: input.radiusKm,
        windSpeedMs: wind ? (input.windSpeedMs ?? null) : null,
        windGustMs: wind
          ? (input.windGustMs ?? input.windSpeedMs ?? null)
          : null,
        windFromDeg: wind ? (input.windFromDeg ?? null) : null,
        startsAt: now,
        endsAt: new Date(now.getTime() + input.durationMin * 60_000),
        createdByUserId: userId,
      }),
    );
    const view = toView(saved);
    this.cells.push(view);
    await this.publisher.publish({
      type: 'weather',
      action: 'created',
      cell: presentWeatherCell(view),
    });
    return view;
  }

  /** La consola corta una celda antes de tiempo. */
  async end(id: string): Promise<WeatherCellView> {
    const cell = this.cells.find((row) => row.id === id);
    if (!cell) {
      throw new NotFoundException(WEATHER_NOT_FOUND);
    }
    const now = simClock.now();
    if (now < cell.endsAt) {
      cell.endsAt = now;
      await this.repo.update({ id }, { endsAt: now });
    }
    await this.announceEnd(cell);
    return cell;
  }

  /** RF-40: el reinicio del escenario borra todo el clima. */
  async clearAll(): Promise<void> {
    await this.repo.clear();
    this.cells = [];
    this.ended.clear();
  }

  private async announceExpired(): Promise<void> {
    const now = simClock.now();
    for (const cell of this.cells) {
      if (
        !this.ended.has(cell.id) &&
        !isActive(cell, now) &&
        now >= cell.endsAt
      ) {
        await this.announceEnd(cell);
      }
    }
  }

  private async announceEnd(cell: WeatherCellView): Promise<void> {
    if (this.ended.has(cell.id)) {
      return;
    }
    this.ended.add(cell.id);
    await this.publisher.publish({
      type: 'weather',
      action: 'ended',
      cell: presentWeatherCell(cell),
    });
  }
}

/** Lo que llega de la consola, con las reglas que el DTO no puede cruzar. */
export function assertWeatherInput(input: NewWeatherCell): void {
  if (input.kind !== WeatherKind.WIND) {
    return;
  }
  if (input.windSpeedMs == null || input.windFromDeg == null) {
    throw new BadRequestException(WIND_NEEDS_SPEED);
  }
  if (input.windGustMs != null && input.windGustMs < input.windSpeedMs) {
    throw new BadRequestException(GUST_BELOW_SPEED);
  }
}

export type WeatherCellJson = Omit<WeatherCellView, 'startsAt' | 'endsAt'> & {
  startsAt: string;
  endsAt: string;
};

export function presentWeatherCell(cell: WeatherCellView): WeatherCellJson {
  return {
    ...cell,
    startsAt: cell.startsAt.toISOString(),
    endsAt: cell.endsAt.toISOString(),
  };
}

function toView(row: WeatherCell): WeatherCellView {
  return {
    id: row.id,
    kind: row.kind,
    latitude: row.latitude,
    longitude: row.longitude,
    radiusKm: row.radiusKm,
    windSpeedMs: row.windSpeedMs,
    windGustMs: row.windGustMs,
    windFromDeg: row.windFromDeg,
    startsAt: row.startsAt,
    endsAt: row.endsAt,
  };
}
