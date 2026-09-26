import { IsBoolean } from 'class-validator';

export class SetHubSuspensionDto {
  @IsBoolean({ message: 'Debes indicar si la central queda suspendida.' })
  suspended: boolean;
}
