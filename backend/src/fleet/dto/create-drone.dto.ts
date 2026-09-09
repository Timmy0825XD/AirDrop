import { Transform } from 'class-transformer';
import { IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class CreateDroneDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El identificador es obligatorio.' })
  @MinLength(1, { message: 'El identificador es obligatorio.' })
  @MaxLength(FIELD_LIMITS.droneIdentifier, {
    message: `El identificador no puede superar ${FIELD_LIMITS.droneIdentifier} caracteres.`,
  })
  identifier: string;

  @IsUUID('4', { message: 'El modelo de dron no es válido.' })
  droneModelId: string;

  @IsUUID('4', { message: 'La central no es válida.' })
  hubId: string;
}
