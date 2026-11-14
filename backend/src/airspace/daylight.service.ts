import { Injectable } from '@nestjs/common';
import { LngLat } from '../routing/routing.rules';
import {
  REGION_REFERENCE,
  SunTimes,
  fitsDaylight,
  isDaylight,
  sunTimes,
} from './daylight.rules';

/**
 * RF-44: la ventana de luz del día. Es un servicio (y no solo reglas) para
 * que las pruebas que no tratan de la hora no dependan de cuándo se corren.
 */
@Injectable()
export class DaylightService {
  fits(now: Date, point: LngLat, missionMs: number): boolean {
    return fitsDaylight(now, point, missionMs);
  }

  isDaylight(now: Date, point: LngLat = REGION_REFERENCE): boolean {
    return isDaylight(now, point);
  }

  sun(now: Date, point: LngLat = REGION_REFERENCE): SunTimes {
    return sunTimes(now, point);
  }
}
