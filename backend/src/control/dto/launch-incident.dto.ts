import { IsIn } from 'class-validator';
import {
  CONSOLE_INCIDENT_KINDS,
  IncidentKind,
} from '../../common/enums/incident-kind.enum';

/** CU-38: un incidente del catálogo de RF-34 sobre un dron en vuelo. */
export class LaunchIncidentDto {
  @IsIn(CONSOLE_INCIDENT_KINDS, {
    message:
      'El incidente debe ser del catálogo: batería, motores, GPS, enlace, refrigeración, choque o dron perdido.',
  })
  kind: IncidentKind;
}
