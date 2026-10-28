import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { ScheduleKind } from '../../common/enums/schedule-kind.enum';
import { MAX_EVERY_WEEKS, MAX_PLAN_DATES } from '../plan-schedule.rules';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/**
 * RU-30: el calendario del plan. Las reglas que cruzan campos (fin o número
 * de entregas, 3 meses, franjas) las valida `buildSchedule`.
 */
export class PlanScheduleDto {
  @IsEnum(ScheduleKind, {
    message: 'El calendario debe ser semanal, mensual o de fechas sueltas.',
  })
  kind: ScheduleKind;

  @IsOptional()
  @Matches(ISO_DATE, { message: 'La fecha de inicio debe ser AAAA-MM-DD.' })
  startDate?: string;

  @IsOptional()
  @Matches(ISO_DATE, { message: 'La fecha de fin debe ser AAAA-MM-DD.' })
  endDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'El número de entregas debe ser un entero.' })
  @Min(1, { message: 'El plan necesita al menos una entrega.' })
  @Max(100, { message: 'Son demasiadas entregas para un plan.' })
  count?: number;

  @IsOptional()
  @IsArray({ message: 'Los días de la semana no son válidos.' })
  @ArrayMaxSize(7, { message: 'Una semana tiene 7 días.' })
  @Type(() => Number)
  @IsInt({ each: true, message: 'Los días de la semana van de 1 a 7.' })
  @Min(1, { each: true, message: 'Los días de la semana van de 1 a 7.' })
  @Max(7, { each: true, message: 'Los días de la semana van de 1 a 7.' })
  daysOfWeek?: number[];

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'La repetición debe ser cada 1 a 4 semanas.' })
  @Min(1, { message: 'La repetición debe ser cada 1 a 4 semanas.' })
  @Max(MAX_EVERY_WEEKS, {
    message: 'La repetición debe ser cada 1 a 4 semanas.',
  })
  everyWeeks?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'El día del mes va de 1 a 31.' })
  @Min(1, { message: 'El día del mes va de 1 a 31.' })
  @Max(31, { message: 'El día del mes va de 1 a 31.' })
  dayOfMonth?: number;

  @IsOptional()
  @IsArray({ message: 'Las fechas no son válidas.' })
  @ArrayMinSize(1, { message: `Elige entre 1 y ${MAX_PLAN_DATES} fechas.` })
  @ArrayMaxSize(MAX_PLAN_DATES, {
    message: `Elige entre 1 y ${MAX_PLAN_DATES} fechas.`,
  })
  @Matches(ISO_DATE, { each: true, message: 'Cada fecha debe ser AAAA-MM-DD.' })
  dates?: string[];

  @Matches(/^\d{2}:\d{2}$/, { message: 'La hora debe ser HH:MM.' })
  time: string;
}

/** Vista previa: las fechas y franjas que dejaría un calendario. */
export class PreviewPlanDto {
  @ValidateNested()
  @Type(() => PlanScheduleDto)
  schedule: PlanScheduleDto;

  @IsOptional()
  @Matches(ISO_DATE, {
    message: 'La vigencia de la fórmula debe ser AAAA-MM-DD.',
  })
  prescriptionValidUntil?: string;
}

/** Cambiar el calendario o la hora de un plan activo. */
export class UpdatePlanScheduleDto {
  @ValidateNested()
  @Type(() => PlanScheduleDto)
  schedule: PlanScheduleDto;
}
