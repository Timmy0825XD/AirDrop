import { IsEnum, IsOptional } from 'class-validator';
import { HubStatus } from '../../common/enums/hub-status.enum';

export class ListHubsQueryDto {
  @IsOptional()
  @IsEnum(HubStatus, { message: 'El estado de la central no es válido.' })
  status?: HubStatus;
}
