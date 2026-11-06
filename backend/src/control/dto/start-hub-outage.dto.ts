import { IsInt, Max, Min } from 'class-validator';

/** RF-36, CU-38: cuánto dura el apagón de una central, en hora simulada. */
export class StartHubOutageDto {
  @IsInt({ message: 'La duración va en minutos enteros.' })
  @Min(5, { message: 'La duración va de 5 a 240 minutos.' })
  @Max(240, { message: 'La duración va de 5 a 240 minutos.' })
  durationMin: number;
}
