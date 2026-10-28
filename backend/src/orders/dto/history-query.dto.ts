import { IsEnum, IsInt, IsOptional, Matches, Max, Min } from 'class-validator';
import { OrderStatus } from '../../common/enums/order-status.enum';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export const HISTORY_MAX_PAGE_SIZE = 50;

/** HU-36: filtros del histórico de misiones de la central. */
export class HistoryQueryDto {
  @IsOptional()
  @Matches(ISO_DATE, { message: 'La fecha inicial debe ser AAAA-MM-DD.' })
  from?: string;

  @IsOptional()
  @Matches(ISO_DATE, { message: 'La fecha final debe ser AAAA-MM-DD.' })
  to?: string;

  @IsOptional()
  @IsEnum(OrderStatus, { message: 'El estado no es válido.' })
  status?: OrderStatus;

  @IsOptional()
  @IsInt({ message: 'La página debe ser un número entero.' })
  @Min(1, { message: 'La página empieza en 1.' })
  page?: number;

  @IsOptional()
  @IsInt({ message: 'El tamaño de página debe ser un número entero.' })
  @Min(1, { message: 'El tamaño de página es al menos 1.' })
  @Max(HISTORY_MAX_PAGE_SIZE, {
    message: `El tamaño de página es máximo ${HISTORY_MAX_PAGE_SIZE}.`,
  })
  pageSize?: number;
}
