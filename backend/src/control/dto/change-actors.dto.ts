import { IsBoolean, IsOptional } from 'class-validator';

/** RF-37: encender o apagar los actores. Lo que no llega se queda como estaba. */
export class ChangeActorsDto {
  @IsOptional()
  @IsBoolean({
    message: 'El despachador automático debe ser verdadero o falso.',
  })
  autoDispatcher?: boolean;

  @IsOptional()
  @IsBoolean({ message: 'El flujo de pedidos debe ser verdadero o falso.' })
  orderFlow?: boolean;
}
