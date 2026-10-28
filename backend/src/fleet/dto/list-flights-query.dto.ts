import { IsOptional, IsUUID } from 'class-validator';

/** Sin central, los vuelos de todas las centrales del operador. */
export class ListFlightsQueryDto {
  @IsOptional()
  @IsUUID('4', { message: 'La central no es válida.' })
  hubId?: string;
}
