import { IsBoolean, IsIn, IsOptional } from 'class-validator';
import { CHAOS_INTENSITIES } from '../chaos.rules';
import type { ChaosIntensity } from '../chaos.rules';

/** RF-38: encender o apagar el caos y su intensidad. Lo que no llega se queda. */
export class ChangeChaosDto {
  @IsOptional()
  @IsBoolean({ message: 'El modo caos debe ser verdadero o falso.' })
  enabled?: boolean;

  @IsOptional()
  @IsIn(CHAOS_INTENSITIES, {
    message: 'La intensidad debe ser baja, media o alta.',
  })
  intensity?: ChaosIntensity;
}
