import { IsBoolean } from 'class-validator';

/** RF-49: el operador pone o quita el compartimento de frío, en tierra. */
export class SetColdCompartmentDto {
  @IsBoolean({ message: 'Indica si el compartimento queda instalado.' })
  installed: boolean;
}
