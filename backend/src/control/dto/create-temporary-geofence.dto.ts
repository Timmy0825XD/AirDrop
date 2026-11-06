import { IsInt, Max, Min } from 'class-validator';
import { CreateGeofenceDto } from '../../geofences/dto/create-geofence.dto';

/** RF-36, CU-38: una geovalla que vence sola, desde la consola. */
export class CreateTemporaryGeofenceDto extends CreateGeofenceDto {
  @IsInt({ message: 'La duración va en minutos enteros.' })
  @Min(5, { message: 'La duración va de 5 a 240 minutos.' })
  @Max(240, { message: 'La duración va de 5 a 240 minutos.' })
  durationMin: number;
}
