import { IsBoolean, IsOptional } from 'class-validator';

export class AuthorizeOrderDto {
  @IsOptional()
  @IsBoolean({ message: 'La verificación de la fórmula debe ser sí o no.' })
  prescriptionVerified?: boolean;
}
