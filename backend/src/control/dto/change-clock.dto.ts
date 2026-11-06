import { IsBoolean, IsIn, IsOptional } from 'class-validator';
import { CLOCK_SPEEDS } from '../../common/clock/clock.rules';
import type { ClockSpeed } from '../../common/clock/clock.rules';

/** RF-31: pausa, x1, x2, x4 o x8. Lo que no llega se queda como estaba. */
export class ChangeClockDto {
  @IsOptional()
  @IsIn(CLOCK_SPEEDS, {
    message: 'La velocidad debe ser x1, x2, x4 o x8.',
  })
  speed?: ClockSpeed;

  @IsOptional()
  @IsBoolean({ message: 'La pausa debe ser verdadero o falso.' })
  paused?: boolean;
}
