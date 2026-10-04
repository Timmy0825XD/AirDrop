import { IsOptional, IsUUID } from 'class-validator';

export class CatalogQueryDto {
  @IsOptional()
  @IsUUID('4', { message: 'La central no es válida.' })
  hubId?: string;
}
