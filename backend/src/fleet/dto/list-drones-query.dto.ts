import { IsUUID } from 'class-validator';

export class ListDronesQueryDto {
  @IsUUID('4', { message: 'La central no es válida.' })
  hubId: string;
}
