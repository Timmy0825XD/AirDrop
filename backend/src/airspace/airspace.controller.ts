import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { simClock } from '../common/clock/sim-clock';
import { AirspaceService } from './airspace.service';
import { DaylightService } from './daylight.service';

@ApiTags('Espacio aéreo')
@ApiBearerAuth()
@Controller('airspace')
@UseGuards(JwtAuthGuard)
export class AirspaceController {
  constructor(
    private readonly airspace: AirspaceService,
    private readonly daylight: DaylightService,
  ) {}

  /** RF-43: las zonas legales, para dibujarlas en cualquier mapa. */
  @Get('zones')
  zones() {
    return this.airspace.view();
  }

  /**
   * RF-44: salida y puesta del sol del día simulado en la región, y si ahora
   * se puede volar. La app lo muestra; la decisión aplica la regla.
   */
  @Get('daylight')
  daylightNow() {
    const now = simClock.now();
    const sun = this.daylight.sun(now);
    return {
      date: sun.date,
      sunrise: sun.sunrise.toISOString(),
      sunset: sun.sunset.toISOString(),
      now: now.toISOString(),
      daylight: this.daylight.isDaylight(now),
    };
  }
}
