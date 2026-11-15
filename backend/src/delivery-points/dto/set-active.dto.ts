import { IsBoolean } from 'class-validator';

export class SetDeliveryPointActiveDto {
  @IsBoolean({ message: 'Indica si el punto queda activo.' })
  active: boolean;
}
