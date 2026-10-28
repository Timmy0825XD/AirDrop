import { Matches } from 'class-validator';

/** Nueva franja de una entrega: el mismo día o el siguiente. */
export class RescheduleOccurrenceDto {
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'La fecha debe ser AAAA-MM-DD.' })
  date: string;

  @Matches(/^\d{2}:\d{2}$/, { message: 'La hora debe ser HH:MM.' })
  time: string;
}
