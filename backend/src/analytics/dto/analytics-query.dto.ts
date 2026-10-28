import { IsOptional, IsUUID, Matches } from 'class-validator';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** Periodo en fechas de Colombia (`YYYY-MM-DD`, ambas incluidas). */
export class AnalyticsQueryDto {
  @IsOptional()
  @Matches(ISO_DATE, { message: 'La fecha inicial debe ser AAAA-MM-DD.' })
  from?: string;

  @IsOptional()
  @Matches(ISO_DATE, { message: 'La fecha final debe ser AAAA-MM-DD.' })
  to?: string;

  @IsOptional()
  @IsUUID('4', { message: 'La central no es válida.' })
  hubId?: string;
}
