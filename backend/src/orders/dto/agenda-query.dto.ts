import { Matches } from 'class-validator';

/** Día operativo de la agenda del despachador, en calendario de Colombia. */
export class AgendaQueryDto {
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha de la agenda debe ser AAAA-MM-DD.',
  })
  date: string;
}
