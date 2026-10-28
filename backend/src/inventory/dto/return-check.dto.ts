import { IsBoolean } from 'class-validator';

export class ReturnCheckDto {
  /** El despachador revisó el empaque del paquete devuelto. */
  @IsBoolean({ message: 'Indica si el empaque llegó íntegro.' })
  packagingIntact: boolean;
}
