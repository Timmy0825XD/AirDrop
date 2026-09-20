import { IsBoolean } from 'class-validator';

export class SetUserSuspensionDto {
  @IsBoolean({ message: 'Debes indicar si la cuenta queda suspendida.' })
  suspended: boolean;
}
